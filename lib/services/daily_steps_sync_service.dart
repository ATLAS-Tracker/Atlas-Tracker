import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller_factory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStepsSyncService with WidgetsBindingObserver {

  final HiveDBProvider _hive;
  final SupabaseDailyStepsService _service;
  final Connectivity _connectivity;
  final Logger _log = Logger('DailyStepsSyncService');
  final StepTrackingControllerFactory _stepTrackingFactory;
  final String? Function()? _userIdProvider;

  DailyStepsSyncService({
    HiveDBProvider? hive,
    SupabaseDailyStepsService? service,
    Connectivity? connectivity,
    String? Function()? userIdProvider,
    StepTrackingControllerFactory? stepTrackingFactory,
  })  : _hive = hive ?? locator<HiveDBProvider>(),
        _service = service ?? SupabaseDailyStepsService(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        _userIdProvider = userIdProvider,
        _stepTrackingFactory =
            stepTrackingFactory ?? locator<StepTrackingControllerFactory>();

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

      final stepsBox = _hive.stepsDateBox.get(HiveDBProvider.stepsDateEntryKey);

      if (stepsBox == null) {
        _log.fine('No steps data to sync.');
        return;
      }

      final steps = _stepTrackingFactory.dailyStepsFromBox(stepsBox);
      if (steps % 100 >= 0 && steps % 100 <= 10) {
        final entries = [
          {
            'user_id': userId,
            'date': DateUtils.dateOnly(DateTime.now()).toIso8601String(),
            'steps': steps,
          }
        ];

        // Envoi au backend
        await _service.upsertDailySteps(entries);
      } else {
        _log.fine('Steps not in sync range, skipping upsert.');
      }

    } catch (e, s) {
      _log.severe('Failed to sync daily steps: $e', e, s);
    }
  }
}
