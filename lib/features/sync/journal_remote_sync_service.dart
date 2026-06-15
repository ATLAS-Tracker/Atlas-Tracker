import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Row-based Supabase sync for journal entries and recipes.
///
/// Tables expected on Supabase:
/// - `user_intakes(user_id, record_id, payload, updated_at)`
/// - `user_recipes(user_id, record_id, payload, updated_at)`
///
/// The payload stores the existing DBO JSON. This keeps the app schema stable
/// while allowing row-level sync independent of the legacy ZIP export.
class JournalRemoteSyncService {
  JournalRemoteSyncService({
    required IntakeRepository intakeRepository,
    required RecipeRepository recipeRepository,
    required ConfigRepository configRepository,
    required SupabaseClient client,
    required HiveDBProvider hive,
  })  : _intakeRepository = intakeRepository,
        _recipeRepository = recipeRepository,
        _configRepository = configRepository,
        _client = client,
        _hive = hive;

  static const int _batchSize = 100;
  static const Duration _autoPushDebounce = Duration(seconds: 5);
  static const String intakesTable = 'user_intakes';
  static const String recipesTable = 'user_recipes';

  final IntakeRepository _intakeRepository;
  final RecipeRepository _recipeRepository;
  final ConfigRepository _configRepository;
  final SupabaseClient _client;
  final HiveDBProvider _hive;
  final Logger _log = Logger('JournalRemoteSyncService');

  final List<StreamSubscription<BoxEvent>> _subscriptions = [];
  Timer? _pushDebounce;
  bool _syncing = false;

  Future<void> startAutoPush() async {
    await stopAutoPush();
    _subscriptions.addAll([
      _hive.intakeBox.watch().listen((_) => _scheduleLocalPush()),
      _hive.recipeBox.watch().listen((_) => _scheduleLocalPush()),
    ]);
  }

  Future<void> stopAutoPush() async {
    _pushDebounce?.cancel();
    _pushDebounce = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _scheduleLocalPush() {
    _pushDebounce?.cancel();
    _pushDebounce = Timer(_autoPushDebounce, () {
      unawaited(syncLocalToRemote());
    });
  }

  Future<void> syncAtStartup() async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (!await _canSync()) return;
      await _syncIntakesBidirectional();
      await _syncRecipesBidirectional();
    } catch (error, stack) {
      _log.warning('Journal startup sync failed; continuing with local data.',
          error, stack);
    } finally {
      _syncing = false;
    }
  }

  Future<void> syncLocalToRemote() async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (!await _canSync()) return;
      final localIntakes = await _intakeRepository.getAllIntakesDBO();
      final localRecipes = await _recipeRepository.getAllRecipeDBOs();
      await _upsertIntakes(localIntakes);
      await _upsertRecipes(localRecipes);
      _log.fine(
        'Journal local push completed: intakes=${localIntakes.length}, recipes=${localRecipes.length}.',
      );
    } catch (error, stack) {
      _log.warning('Journal local push failed.', error, stack);
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _canSync() async {
    if (_client.auth.currentSession == null) {
      _log.fine('No Supabase session; skipping journal sync.');
      return false;
    }
    if (!await _configRepository.getSupabaseSyncEnabled()) {
      _log.fine('Supabase sync disabled; skipping journal sync.');
      return false;
    }
    return true;
  }

  Future<void> _syncIntakesBidirectional() async {
    final local = await _intakeRepository.getAllIntakesDBO();
    final remote = await _fetchRemoteIntakes();

    final toSave = remoteIntakesToSave(local: local, remote: remote);
    for (final intake in toSave) {
      final current = local.firstWhere(
        (item) => item.id == intake.id,
        orElse: () => intake,
      );
      if (current.id == intake.id && current != intake) {
        await _intakeRepository
            .deleteIntake(IntakeEntity.fromIntakeDBO(current));
      }
      await _intakeRepository.addAllIntakeDBOs([intake]);
    }

    final toUpload = localIntakesToUpload(local: local, remote: remote);
    await _upsertIntakes(toUpload);

    _log.fine(
        'Journal intakes sync: pulled=${toSave.length}, pushed=${toUpload.length}.');
  }

  Future<void> _syncRecipesBidirectional() async {
    final local = await _recipeRepository.getAllRecipeDBOs();
    final remote = await _fetchRemoteRecipes();

    final toSave = remoteRecipesToSave(local: local, remote: remote);
    if (toSave.isNotEmpty) {
      await _recipeRepository.addAllRecipeDBOs(toSave);
    }

    final toUpload = localRecipesToUpload(local: local, remote: remote);
    await _upsertRecipes(toUpload);

    _log.fine(
        'Journal recipes sync: pulled=${toSave.length}, pushed=${toUpload.length}.');
  }

  Future<List<IntakeDBO>> _fetchRemoteIntakes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from(intakesTable)
        .select('payload')
        .eq('user_id', userId);
    return rows
        .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row as Map))
        .map((row) => Map<String, dynamic>.from(row['payload'] as Map))
        .map(IntakeDBO.fromJson)
        .toList();
  }

  Future<List<RecipesDBO>> _fetchRemoteRecipes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from(recipesTable)
        .select('payload')
        .eq('user_id', userId);
    return rows
        .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row as Map))
        .map((row) => Map<String, dynamic>.from(row['payload'] as Map))
        .map(RecipesDBO.fromJson)
        .toList();
  }

  Future<void> _upsertIntakes(List<IntakeDBO> intakes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || intakes.isEmpty) return;
    for (var i = 0; i < intakes.length; i += _batchSize) {
      final batch = intakes.skip(i).take(_batchSize).map((intake) {
        return {
          'user_id': userId,
          'record_id': intake.id,
          'payload': intake.toJson(),
          'updated_at': intake.updatedAt.toUtc().toIso8601String(),
        };
      }).toList();
      await _client
          .from(intakesTable)
          .upsert(batch, onConflict: 'user_id,record_id');
    }
  }

  Future<void> _upsertRecipes(List<RecipesDBO> recipes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || recipes.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < recipes.length; i += _batchSize) {
      final batch = recipes.skip(i).take(_batchSize).map((recipe) {
        return {
          'user_id': userId,
          'record_id': recipeKey(recipe),
          'payload': recipe.toJson(),
          'updated_at': now,
        };
      }).toList();
      await _client
          .from(recipesTable)
          .upsert(batch, onConflict: 'user_id,record_id');
    }
  }

  static List<IntakeDBO> remoteIntakesToSave({
    required List<IntakeDBO> local,
    required List<IntakeDBO> remote,
  }) {
    final localById = {for (final intake in local) intake.id: intake};
    return remote.where((remoteIntake) {
      final localIntake = localById[remoteIntake.id];
      return localIntake == null ||
          remoteIntake.updatedAt.isAfter(localIntake.updatedAt);
    }).toList();
  }

  static List<IntakeDBO> localIntakesToUpload({
    required List<IntakeDBO> local,
    required List<IntakeDBO> remote,
  }) {
    final remoteById = {for (final intake in remote) intake.id: intake};
    return local.where((localIntake) {
      final remoteIntake = remoteById[localIntake.id];
      return remoteIntake == null ||
          localIntake.updatedAt.isAfter(remoteIntake.updatedAt);
    }).toList();
  }

  static List<RecipesDBO> remoteRecipesToSave({
    required List<RecipesDBO> local,
    required List<RecipesDBO> remote,
  }) {
    final localKeys = local.map(recipeKey).toSet();
    return remote
        .where((recipe) => !localKeys.contains(recipeKey(recipe)))
        .toList();
  }

  static List<RecipesDBO> localRecipesToUpload({
    required List<RecipesDBO> local,
    required List<RecipesDBO> remote,
  }) {
    final remoteKeys = remote.map(recipeKey).toSet();
    return local
        .where((recipe) => !remoteKeys.contains(recipeKey(recipe)))
        .toList();
  }

  static String recipeKey(RecipesDBO recipe) {
    return recipe.recipe.code ?? recipe.recipe.name ?? '';
  }
}
