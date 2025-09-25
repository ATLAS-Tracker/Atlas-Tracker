import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/services/daily_steps_queue_entry.dart';
import 'package:opennutritracker/services/daily_steps_service.dart';
import 'package:opennutritracker/features/sync/change_isolate.dart';

class DailyStepsQueueIsolate extends ChangeIsolate<DailyStepsQueueEntry> {
  DailyStepsQueueIsolate(
    Box<DailyStepsQueueEntry> queueBox, {
    DailyStepsService? dailyStepsService,
    Connectivity? connectivity,
  })  : _dailyStepsService = dailyStepsService,
        _connectivity = connectivity ?? locator<Connectivity>(),
        _log = Logger('DailyStepsQueueIsolate'),
        _queueBox = queueBox,
        super(
          box: queueBox,
          extractor: _extractEntry,
        );
  final Box<DailyStepsQueueEntry> _queueBox;
  final Connectivity _connectivity;
  DailyStepsService? _dailyStepsService;
  final Logger _log;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _syncing = false;

  static DailyStepsQueueEntry? _extractEntry(BoxEvent event) {
    final value = event.value;
    if (event.deleted || value is! DailyStepsQueueEntry) {
      return null;
    }
    return value;
  }

  DailyStepsService? get _service {
    if (_dailyStepsService != null) {
      return _dailyStepsService;
    }
    if (!locator.isRegistered<DailyStepsService>()) {
      return null;
    }
    _dailyStepsService = locator<DailyStepsService>();
    return _dailyStepsService;
  }

  @override
  Future<void> start() async {
    _log.info('Starting DailyStepsQueueIsolate...');
    onItemCollected ??= _attemptSync;
    await super.start();

    // Attempt an initial sync when starting.
    await _attemptSync();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    _log.fine('Connectivity listener registered.');
  }

  @override
  Future<void> stop() async {
    _log.info('Stopping DailyStepsQueueIsolate...');
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await super.stop();
    _log.info('DailyStepsQueueIsolate stopped.');
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    _log.fine('Connectivity changed: $result');
    if (result != ConnectivityResult.none) {
      _attemptSync();
    }
  }

  Future<void> attemptSync() => _attemptSync();

  Future<void> _attemptSync() async {
    if (_syncing) {
      _log.fine('Sync already in progress. Skipping.');
      return;
    }

    final service = _service;
    if (service == null) {
      _log.finest('DailyStepsService not available yet.');
      return;
    }

    _syncing = true;
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _log.fine('No connectivity available.');
        return;
      }

      final entries = _queueBox.values.toList();
      if (entries.isEmpty) {
        _log.fine('Queue is empty.');
        return;
      }

      _log.info('Syncing ${entries.length} queued step entries to Supabase.');
      for (final entry in entries) {
        try {
          await service.syncStepsToSupabase(entry.date, entry.steps);
          await entry.delete();
          await removeItems([entry]);
          _log.fine('Synced steps for ${entry.date} and removed from queue.');
        } catch (error, stackTrace) {
          _log.warning(
            'Failed to sync queued steps for ${entry.date}: $error',
            error,
            stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      _log.severe('Unexpected error while syncing queued steps.', error, stackTrace);
    } finally {
      _syncing = false;
    }
  }
}
