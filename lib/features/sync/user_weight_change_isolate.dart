import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/sync/change_isolate.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';

/// Internal representation of a pending weight synchronization operation.
class _UserWeightSyncOp {
  final DateTime date;
  final bool isDeletion;

  const _UserWeightSyncOp(this.date, {this.isDeletion = false});

  @override
  bool operator ==(Object other) =>
      other is _UserWeightSyncOp &&
      other.date == date &&
      other.isDeletion == isDeletion;

  @override
  int get hashCode => date.hashCode ^ isDeletion.hashCode;
}

class UserWeightChangeIsolate extends ChangeIsolate<_UserWeightSyncOp> {
  final SupabaseUserWeightService _service;
  final Connectivity _connectivity;
  final int batchSize;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;
  final Logger _log = Logger('UserWeightChangeIsolate');

  UserWeightChangeIsolate(
    Box<UserWeightDbo> box, {
    SupabaseUserWeightService? service,
    Connectivity? connectivity,
    this.batchSize = 20,
  })  : _service = service ?? SupabaseUserWeightService(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        super(
          box: box,
          extractor: _extractorWithLogging,
          onItemCollected: null,
        );

  /// Returns the pending synchronization operations.
  Future<List<_UserWeightSyncOp>> _getPendingOps() => getItems();

  /// Convenient proxy to get the pending weight dates only.
  Future<List<DateTime>> getModifiedWeights() async =>
      (await _getPendingOps()).map((e) => e.date).toList();

  /* ---------- Lifecycle ---------- */

  @override
  Future<void> start() async {
    _log.info('Starting UserWeightChangeIsolate...');
    onItemCollected ??= _attemptSync;

    await super.start();
    _log.fine('ChangeIsolate started.');

    await _attemptSync();

    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _log.fine('Connectivity listener started.');
  }

  @override
  Future<void> stop() async {
    _log.info('Stopping UserWeightChangeIsolate...');
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await super.stop();
    _log.info('UserWeightChangeIsolate stopped.');
  }

  /* ---------- Connectivity management ---------- */

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    _log.fine('Connectivity changed: $result');
    if (result != ConnectivityResult.none) {
      _log.fine('Internet available, attempting sync...');
      _attemptSync();
    } else {
      _log.fine('No internet connection.');
    }
  }

  /* ---------- Supabase sync ---------- */

  String _keyForDate(DateTime date) =>
      DateTime(date.year, date.month, date.day).toString();

  Future<void> _attemptSync() async {
    if (_syncing) {
      _log.fine('Sync already in progress, skipping.');
      return;
    }
    if (locator.isRegistered<ConfigRepository>()) {
      final configRepo = locator<ConfigRepository>();
      final enabled = await configRepo.getSupabaseSyncEnabled();
      if (!enabled) {
        _log.fine('Supabase sync disabled, skipping.');
        return;
      }
    }
    _syncing = true;
    try {
      if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
        _log.fine('No connectivity, aborting sync.');
        return;
      }

      final ops = await _getPendingOps();
      if (ops.isEmpty) {
        _log.fine('No modified weights to sync.');
        return;
      }

      final upserts = <_UserWeightSyncOp>[];
      final deletions = <_UserWeightSyncOp>[];
      for (final op in ops) {
        if (op.isDeletion) {
          deletions.add(op);
        } else {
          upserts.add(op);
        }
      }

      _log.info('Starting sync for ${ops.length} weight operations.');

      for (var i = 0; i < upserts.length; i += batchSize) {
        final batchOps = upserts.skip(i).take(batchSize).toList();
        final entries = <Map<String, dynamic>>[];

        for (final op in batchOps) {
          final dbo = box.get(_keyForDate(op.date)) as UserWeightDbo?;
          if (dbo != null) {
            entries.add(dbo.toJson());
          }
        }

        if (entries.isNotEmpty) {
          _log.info('Upserting ${entries.length} user weights to Supabase.');
          await _service.upsertUserWeights(entries);
        }

        await removeItems(batchOps);
        _log.fine('Batch of ${batchOps.length} upserts synced and removed.');
      }

      for (final op in deletions) {
        _log.info('Deleting user weight ${op.date} from Supabase.');
        try {
          await _service.deleteUserWeight(op.date);
          await removeItems([op]);
          _log.fine('Deleted user weight ${op.date} and removed from queue.');
        } catch (e, stack) {
          _log.warning('Deletion of ${op.date} failed: $e', e, stack);
        }
      }

      _log.info('Sync completed.');
    } catch (e, stack) {
      _log.severe('Sync failed: $e', e, stack);
    } finally {
      _syncing = false;
    }
  }

  /// Extractor with logging for event processing
  static _UserWeightSyncOp? _extractorWithLogging(BoxEvent event) {
    final logger = Logger('UserWeightChangeIsolate');
    if (event.deleted) {
      try {
        return _UserWeightSyncOp(
          DateTime.parse(event.key as String),
          isDeletion: true,
        );
      } catch (e, s) {
        logger.warning(
            'Failed to parse date from key "${event.key}" for deletion event.',
            e,
            s);
        return null;
      }
    }

    final value = event.value;
    if (value is UserWeightDbo) {
      return _UserWeightSyncOp(value.date);
    }

    return null;
  }
}
