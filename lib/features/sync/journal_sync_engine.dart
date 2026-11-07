import 'dart:async';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'sync_preparation.dart';

/// Pull, merge and prepared upload run in one queue; a request during a run
/// schedules another pass instead of being dropped.
class JournalSyncEngine {
  final HiveDBProvider hive;
  final SupabaseClient client;
  final ConfigRepository config;
  final IntakeRepository intakes;
  final RecipeRepository recipes;
  final TrackedDayRepository days;
  final UserWeightRepository weights;
  final Duration requestTimeout;
  final _log = Logger('JournalSyncEngine');
  final _subscriptions = <StreamSubscription<BoxEvent>>[];
  Future<void>? _running;
  bool _requested = false;
  bool _stopped = false;
  Timer? _timer;
  bool? _versionedSchema;

  JournalSyncEngine(
      {required this.hive,
      required this.client,
      required this.config,
      required this.intakes,
      required this.recipes,
      required this.days,
      required this.weights,
      this.requestTimeout = const Duration(seconds: 8)});

  bool _owns(String owner) =>
      !_stopped &&
      hive.activeUserId == owner &&
      client.auth.currentUser?.id == owner;

  Future<void> start() async {
    await stop();
    _stopped = false;
    _versionedSchema = null;
    for (final box in [
      hive.intakeBox,
      hive.recipeBox,
      hive.trackedDayBox,
      hive.userWeightBox,
      if (hive.syncMetadataBox != null) hive.syncMetadataBox!
    ]) {
      _subscriptions.add(box.watch().listen((_) => _schedule()));
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _schedule([Duration delay = const Duration(seconds: 5)]) {
    if (_stopped) return;
    if (_running != null) {
      _requested = true;
      return;
    }
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(sync()));
  }

  Future<void> sync() {
    if (_running != null) {
      _requested = true;
      return _running!;
    }
    final done = Completer<void>();
    _running = done.future;
    unawaited(_drain(done));
    return done.future;
  }

  Future<void> _drain(Completer<void> done) async {
    var failed = false;
    try {
      for (var pass = 0; pass < 3; pass++) {
        _requested = false;
        final owner = client.auth.currentUser?.id;
        if (owner == null ||
            !_owns(owner) ||
            !await config.getSupabaseSyncEnabled()) {
          break;
        }
        await _syncPass(owner);
        if (!_requested) break;
      }
    } catch (error, stack) {
      failed = true;
      _log.warning(
          'Sync deferred; local data and deletion versions are retained.',
          error,
          stack);
    } finally {
      _running = null;
      done.complete();
      if (failed || _requested) _schedule(const Duration(seconds: 30));
    }
  }

  String _keyField(String table) => switch (table) {
        'tracked_days' => 'day',
        'user_weight' => 'date',
        _ => 'record_id',
      };

  DateTime _version(Map<String, dynamic> row) =>
      DateTime.tryParse(
          (row['modified_at'] ?? row['updated_at'] ?? row['updatedat'] ?? '')
              .toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Future<List<Map<String, dynamic>>> _fetch(String table, String owner) async {
    final result = <Map<String, dynamic>>[];
    const pageSize = 500;
    for (var offset = 0;; offset += pageSize) {
      if (!_owns(owner)) return [];
      final page = await client
          .from(table)
          .select()
          .eq('user_id', owner)
          .order(_keyField(table))
          .range(offset, offset + pageSize - 1)
          .timeout(requestTimeout);
      result.addAll(page
          .where((row) => row['user_id'] == owner)
          .map((row) => Map<String, dynamic>.from(row)));
      if (page.length < pageSize) return result;
    }
  }

  Future<void> _syncPass(String owner) async {
    if (!await _supportsVersionedSchema(owner)) {
      await _syncLegacy(owner);
      return;
    }
    final remote = <String, List<Map<String, dynamic>>>{};
    for (final table in SyncPreparation.tables) {
      remote[table] = await _fetch(table, owner);
    }
    if (!_owns(owner)) return;
    for (final table in [
      'user_intakes',
      'user_recipes',
      'user_weight',
      'tracked_days'
    ]) {
      for (final row in remote[table]!) {
        if (!_owns(owner)) return;
        await _merge(table, row, owner);
      }
    }
    if (!_owns(owner)) return;
    final snapshot = _prepare(owner);
    for (final table in [
      'user_intakes',
      'user_recipes',
      'user_weight',
      'tracked_days'
    ]) {
      final keyField = _keyField(table);
      final byId = {
        for (final row in remote[table]!) row[keyField].toString(): row
      };
      final pending = snapshot.rows(table).where((row) {
        final existing = byId[row[keyField].toString()];
        return existing == null || _version(row).isAfter(_version(existing));
      }).toList();
      for (var offset = 0; offset < pending.length; offset += 100) {
        if (!_owns(owner)) return;
        final conflict = 'user_id,$keyField';
        await client
            .from(table)
            .upsert(pending.skip(offset).take(100).toList(),
                onConflict: conflict)
            .timeout(requestTimeout);
        _requested = true; // Read the server's canonical projection next pass.
        if (table == 'user_weight' && _owns(owner)) {
          final metadata = SyncMetadata(hive.syncMetadataBox);
          for (final row in pending.skip(offset).take(100)) {
            if (!_owns(owner)) return;
            await metadata.acknowledgeWeight(
                row['date'].toString(), _version(row));
          }
        }
      }
    }
  }

  Future<bool> _supportsVersionedSchema(String owner) async {
    if (_versionedSchema != null) return _versionedSchema!;
    try {
      for (final table in [
        'user_weight',
        'tracked_days',
        'user_intakes',
        'user_recipes'
      ]) {
        if (!_owns(owner)) return false;
        await client
            .from(table)
            .select('modified_at,deleted_at')
            .eq('user_id', owner)
            .limit(0)
            .timeout(requestTimeout);
      }
      return _versionedSchema = true;
    } on PostgrestException catch (error) {
      if (!['42703', 'PGRST204', 'PGRST205'].contains(error.code)) rethrow;
      _log.info(
          'Using deployed weights/day schema; journal remains in local storage and ZIP backups.');
      return _versionedSchema = false;
    }
  }

  PreparedSyncSnapshot _prepare(String owner) {
    final snapshot = SyncPreparation.fromHive(hive, owner);
    if (snapshot.rejected.isNotEmpty) {
      _log.warning(
          '${snapshot.rejected.length} invalid local records excluded from upload.');
    }
    return snapshot;
  }

  Future<void> _syncLegacy(String owner) async {
    final remoteWeights = await _fetch('user_weight', owner);
    final remoteDays = await _fetch('tracked_days', owner);
    final goals = await client
        .from('coach_macro_goals')
        .select()
        .eq('user_id', owner)
        .order('start_date', ascending: false)
        .limit(1)
        .timeout(requestTimeout);
    if (!_owns(owner)) return;
    final metadata = SyncMetadata(hive.syncMetadataBox);
    for (final row in remoteWeights) {
      if (!_owns(owner)) return;
      if (metadata.pendingWeight(row['date'].toString()) != null) continue;
      await _merge('user_weight', row, owner);
    }
    if (!_owns(owner)) return;
    final snapshot = _prepare(owner);
    final serverGoal =
        MacroGoalEntity.fromHistory(owner, goals, today: DateTime.now());
    final knownJournalDays = {
      ...SyncMetadata(hive.syncMetadataBox).journalDays,
      for (final row in snapshot.rows('user_intakes'))
        if (row['deleted_at'] == null)
          (row['payload'] as Map)['dateTime'].toString(),
    };
    for (final table in ['user_weight', 'tracked_days']) {
      final key = _keyField(table);
      final remoteRows = table == 'user_weight' ? remoteWeights : remoteDays;
      final byId = {for (final row in remoteRows) row[key].toString(): row};
      final uploads = <Map<String, dynamic>>[];
      final uploadVersions = <String, DateTime>{};
      for (final prepared in snapshot.rows(table)) {
        if (!_owns(owner)) return;
        final existing = byId[prepared[key].toString()];
        final pendingWeight = table == 'user_weight'
            ? metadata.pendingWeight(prepared[key].toString())
            : null;
        if (pendingWeight != null &&
            pendingWeight.isAfter(_version(prepared))) {
          continue;
        }
        if (table == 'user_weight' &&
            pendingWeight == null &&
            existing != null &&
            !_version(prepared).isAfter(_version(existing))) {
          continue;
        }
        if (prepared['deleted_at'] != null) {
          if (existing == null) {
            await metadata.acknowledgeWeight(
                prepared[key].toString(), _version(prepared));
            continue;
          }
          await client
              .from(table)
              .delete()
              .eq('user_id', owner)
              .eq(key, prepared[key])
              .timeout(requestTimeout);
          if (!_owns(owner)) return;
          await metadata.acknowledgeWeight(
              prepared[key].toString(), _version(prepared));
          _requested = true;
          continue;
        }
        final wire = Map<String, dynamic>.from(prepared)
          ..remove('modified_at')
          ..remove('deleted_at');
        if (table == 'tracked_days') {
          if (goals.isNotEmpty && serverGoal == null) {
            continue;
          }
          // Never zero a cloud-only history whose journal has not been restored.
          if (existing != null &&
              (existing['caloriesTracked'] as num? ?? 0) > 0 &&
              !knownJournalDays.contains(prepared['day'])) {
            continue;
          }
          if (serverGoal != null &&
              !DateTime.parse(prepared['day'].toString())
                  .isBefore(serverGoal.date)) {
            wire.addAll({
              'carbsGoal': serverGoal.newCarbsGoal,
              'fatGoal': serverGoal.newFatsGoal,
              'proteinGoal': serverGoal.newProteinsGoal,
              'calorieGoal': serverGoal.newCarbsGoal * 4 +
                  serverGoal.newFatsGoal * 9 +
                  serverGoal.newProteinsGoal * 4
            });
          }
        } else {
          final validId =
              RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$');
          final id = existing?['id'] ?? wire['id'];
          wire['id'] = id is String && validId.hasMatch(id)
              ? id
              : IdGenerator.uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8',
                  '$owner/user_weight/${wire['date']}');
        }
        final content = wire.keys.where((field) => field != 'id');
        if (existing != null &&
            content.every((field) => wire[field] == existing[field])) {
          if (table == 'user_weight') {
            await metadata.acknowledgeWeight(
                prepared[key].toString(), _version(prepared));
          }
          continue;
        }
        wire[table == 'user_weight' ? 'updatedat' : 'updated_at'] =
            prepared['modified_at'];
        uploads.add(wire);
        uploadVersions[prepared[key].toString()] = _version(prepared);
      }
      for (var offset = 0; offset < uploads.length; offset += 100) {
        if (!_owns(owner)) return;
        final batch = uploads.skip(offset).take(100).toList();
        await client
            .from(table)
            .upsert(batch, onConflict: 'user_id,$key')
            .timeout(requestTimeout);
        if (!_owns(owner)) return;
        if (table == 'user_weight') {
          for (final row in batch) {
            await metadata.acknowledgeWeight(
                row[key].toString(), uploadVersions[row[key]]!);
          }
        }
        _requested = true;
      }
    }
  }

  DateTime? _localVersion(String table, String id) {
    DateTime? result;
    switch (table) {
      case 'user_intakes':
        for (final row in hive.intakeBox.values.where((row) => row.id == id)) {
          if (result == null || row.updatedAt.isAfter(result)) {
            result = row.updatedAt;
          }
        }
      case 'user_recipes':
        result = hive.recipeBox.get(id)?.updatedAt;
      case 'user_weight':
        for (final row in hive.userWeightBox.values
            .where((row) => row.date.toDayKey() == id)) {
          if (result == null || row.updatedat.isAfter(result)) {
            result = row.updatedat;
          }
        }
      case 'tracked_days':
        result = hive.trackedDayBox.get(id)?.updatedAt;
    }
    return result;
  }

  bool _validIncoming(String table, String owner,
          {IntakeDBO? intake,
          RecipesDBO? recipe,
          UserWeightDbo? weight,
          TrackedDayDBO? day}) =>
      SyncPreparation.prepare(
          userId: owner,
          ownerId: owner,
          intakes: [if (intake != null) intake],
          recipes: [if (recipe != null) recipe],
          days: [if (day != null) day],
          weights: [if (weight != null) weight]).rows(table).isNotEmpty;

  Future<void> _merge(
      String table, Map<String, dynamic> row, String owner) async {
    final id = row[_keyField(table)].toString();
    final version = _version(row);
    if (version
        .isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      return;
    }
    final local = _localVersion(table, id);
    final metadata = SyncMetadata(hive.syncMetadataBox);
    final deletion = metadata.deletedAt(table, id);
    if (row['deleted_at'] != null) {
      if ((local != null && local.isAfter(version)) ||
          (deletion != null && deletion.isAfter(version)) ||
          (local == null && deletion == version)) {
        return;
      }
      switch (table) {
        case 'user_intakes':
          await intakes.deleteIntakeById(id, deletedAt: version);
        case 'user_recipes':
          await recipes.deleteRecipe(id, deletedAt: version);
        case 'user_weight':
          await weights.deleteUserWeightByDate(DateTime.parse(id),
              deletedAt: version);
          await metadata.acknowledgeWeight(id, version);
      }
      return;
    }
    if (deletion != null && !version.isAfter(deletion)) return;
    if (table != 'tracked_days' && local != null && !version.isAfter(local)) {
      return;
    }
    Future<void> Function()? apply;
    try {
      final stamp = version.toUtc().toIso8601String();
      switch (table) {
        case 'user_intakes':
          final payload = Map<String, dynamic>.from(row['payload'] as Map)
            ..['updatedAt'] = stamp;
          final intake = IntakeDBO.fromJson(payload);
          if (intake.id == id && _validIncoming(table, owner, intake: intake)) {
            apply = () => intakes.addAllIntakeDBOs([intake]);
          }
        case 'user_recipes':
          final payload = Map<String, dynamic>.from(row['payload'] as Map)
            ..['updated_at'] = stamp;
          final recipe = RecipesDBO.fromJson(payload);
          if ((recipe.recipe.code ?? recipe.recipe.name) == id &&
              _validIncoming(table, owner, recipe: recipe)) {
            apply = () => recipes.addAllRecipeDBOs([recipe]);
          }
        case 'user_weight':
          final weight = UserWeightDbo.fromJson({...row, 'updatedat': stamp});
          if (_validIncoming(table, owner, weight: weight)) {
            apply = () => weights.addAllUserWeightDBOs([weight]);
          }
        case 'tracked_days':
          final day = TrackedDayDBO.fromJson({...row, 'updated_at': stamp});
          final current = hive.trackedDayBox.get(id);
          final goalsChanged = current != null &&
              (current.calorieGoal != day.calorieGoal ||
                  current.carbsGoal != day.carbsGoal ||
                  current.fatGoal != day.fatGoal ||
                  current.proteinGoal != day.proteinGoal);
          if ((local == null || version.isAfter(local) || goalsChanged) &&
              _validIncoming(table, owner, day: day)) {
            if (current != null && local != null && local.isAfter(version)) {
              day.caloriesBurned = current.caloriesBurned;
              day.updatedAt = local;
            }
            apply = () => days.addAllTrackedDays([day]);
          }
      }
    } catch (error) {
      _log.warning(
          'Invalid remote $table record excluded: $id (${error.runtimeType}).');
    }
    // Storage failures must reach the queue's retry handler.
    if (_owns(owner)) {
      await apply?.call();
      if (apply != null && table == 'user_weight') {
        await metadata.acknowledgeWeight(id, version);
      }
    }
  }
}
