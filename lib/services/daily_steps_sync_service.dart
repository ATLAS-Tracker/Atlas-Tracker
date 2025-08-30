import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStepsSyncService with WidgetsBindingObserver {
  static const _lastSyncKey = '_lastStepsSync';

  final HiveDBProvider _hive;
  final SupabaseDailyStepsService _service;
  final Connectivity _connectivity;
  final Logger _log = Logger('DailyStepsSyncService');
  final String? Function()? _userIdProvider;
  final DateTime Function() _now;

  DailyStepsSyncService({
    HiveDBProvider? hive,
    SupabaseDailyStepsService? service,
    Connectivity? connectivity,
    String? Function()? userIdProvider,
    DateTime Function()? nowProvider,
  })  : _hive = hive ?? locator<HiveDBProvider>(),
        _service = service ?? SupabaseDailyStepsService(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        _userIdProvider = userIdProvider,
        _now = nowProvider ?? DateTime.now;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await syncPendingSteps();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncPendingSteps();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> syncPendingSteps() async {
    try {
      if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
        _log.fine('No connectivity, skipping daily steps sync.');
        return;
      }

      final userId = _userIdProvider?.call() ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _log.fine('No authenticated user, skipping daily steps sync.');
        return;
      }

      final box = _hive.dailyStepsBox;
      final today = DateUtils.dateOnly(_now());
      final lastSyncMillis = box.get(_lastSyncKey);
      final lastSynced = lastSyncMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis)
          : null;

      final keys = box.keys
          .where((k) => k is String && k != _lastSyncKey)
          .cast<String>()
          .toList();

      final dates = keys
          .map(DateTime.parse)
          .where((d) => d.isBefore(today))
          .toList()
        ..sort();

      final pending = dates
          .where((d) => lastSynced == null || d.isAfter(lastSynced))
          .toList();

      if (pending.isEmpty) {
        _log.fine('No daily steps to sync.');
        return;
      }

      final entries = pending
          .map((date) => {
                'user_id': userId,
                'date': date.toIso8601String().split('T').first,
                'steps': box.get(date.toIso8601String(), defaultValue: 0),
              })
          .toList();

      await _service.upsertDailySteps(entries);

      await box.put(_lastSyncKey, pending.last.millisecondsSinceEpoch);
      _log.info('Synced ${entries.length} day(s) of steps.');
    } catch (e, s) {
      _log.severe('Failed to sync daily steps: $e', e, s);
    }
  }
}
