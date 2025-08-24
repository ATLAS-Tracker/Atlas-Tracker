import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart'; // toParsedDay()
import 'package:opennutritracker/features/sync/change_isolate.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:logging/logging.dart';

/// Watches a [TrackedDayDBO] box and synchronizes modified days
/// with Supabase as soon as a connection is available.
class TrackedDayChangeIsolate extends ChangeIsolate<DateTime> {
  final SupabaseTrackedDayService _service;
  final Connectivity _connectivity;
  final int batchSize;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _syncing = false;
  final Logger _log = Logger('TrackedDayChangeIsolate');

  TrackedDayChangeIsolate(
    Box<TrackedDayDBO> box, {
    SupabaseTrackedDayService? service,
    Connectivity? connectivity,
    this.batchSize = 20,
  })  : _service = service ?? SupabaseTrackedDayService(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        super(
          box: box,
          extractor: (event) {
            final value = event.value;
            if (value is TrackedDayDBO) return value.day;
            return null;
          },
          onItemCollected: null, // will be set in start() below
        );

  /// Convenient proxy to get the pending days.
  Future<List<DateTime>> getModifiedDays() => getItems();

  /* ---------- Lifecycle ---------- */

  @override
  Future<void> start() async {
    _log.info('Starting TrackedDayChangeIsolate...');
    // 1️⃣  Attach the callback BEFORE initializing the box watcher
    onItemCollected ??= _attemptSync;

    // 2️⃣  Start the isolate and watcher
    await super.start();
    _log.fine('ChangeIsolate started.');

    // 3️⃣  Immediate attempt (in case there are already pending days)
    await _attemptSync();

    // 4️⃣  Listen to connectivity changes
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _log.fine('Connectivity listener started.');
  }

  @override
  Future<void> stop() async {
    _log.info('Stopping TrackedDayChangeIsolate...');
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await super.stop();
    _log.info('TrackedDayChangeIsolate stopped.');
  }

  /* ---------- Connectivity management ---------- */

  void _onConnectivityChanged(ConnectivityResult result) {
    _log.fine('Connectivity changed: $result');
    if (result != ConnectivityResult.none) {
      _log.fine('Internet available, attempting sync...');
      _attemptSync();
    } else {
      _log.fine('No internet connection.');
    }
  }

  String _toPgDate(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day'; // "YYYY-MM-DD"
  }

  /* ---------- Supabase sync ---------- */

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
    _syncing = true; // prevent overlapping runs immediately
    try {
      if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
        _log.fine('No connectivity, aborting sync.');
        return;
      }

      final days = await getModifiedDays();
      if (days.isEmpty) {
        _log.fine('No modified days to sync.');
        return;
      }

      _log.info('Starting sync for ${days.length} days.');
      for (var i = 0; i < days.length; i += batchSize) {
        final batch = days.skip(i).take(batchSize).toList();
        final entries = <Map<String, dynamic>>[];

        // Convert each day to JSON
        for (final dayKey in batch) {
          final dbo = box.get(dayKey.toParsedDay()) as TrackedDayDBO?;
          if (dbo == null) continue;
          final m = dbo.toJson();
          m['day'] = _toPgDate(dbo.day);
          entries.add(m);
        }

        // If there is something to send…
        if (entries.isNotEmpty) {
          // Double-check that we are still online
          if (await _connectivity.checkConnectivity() ==
              ConnectivityResult.none) {
            _log.warning('Lost connectivity during sync, will retry later.');
            break; // will retry later, do not remove
          }

          _log.info('Upserting ${entries.length} tracked days to Supabase.');
          await _service.upsertTrackedDays(entries);
          await removeItems(batch); // ← only remove after success
          _log.fine('Batch of ${batch.length} days synced and removed.');
        }
      }
      _log.info('Sync completed.');
    } catch (e, stack) {
      _log.severe('Sync failed: $e', e, stack);
    } finally {
      _syncing = false;
    }
  }
}
