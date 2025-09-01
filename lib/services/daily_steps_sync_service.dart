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

      // Charger la dernière synchro
      final lastSyncMillis = box.get(_lastSyncKey) as int?;
      final lastSynced = lastSyncMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis)
          : null;

      // Filtrer uniquement les clés de jours (yyyy-MM-dd)
      final keys = box.keys.where((k) => k is String && k != _lastSyncKey);

      // Convertir en DateTime et inclure le lastSynced lui-même
      final pending = keys
          .map((k) => DateTime.parse(k as String))
          .where((d) => lastSynced == null || !d.isBefore(lastSynced))
          .toList()
        ..sort();

      if (pending.isEmpty) {
        _log.fine('No daily steps to sync.');
        return;
      }

      // Construire les entrées pour l’API
      final entries = pending.map((date) {
        final key =
            DateUtils.dateOnly(date).toIso8601String(); // clé Hive exacte
        return {
          'user_id': userId,
          // Pour l’API on veut une date au format yyyy-MM-dd
          'date': date.toIso8601String().split('T').first,
          'steps': box.get(key, defaultValue: 0),
        };
      }).toList();

      // Envoi au backend
      await _service.upsertDailySteps(entries);

      // Mise à jour de la dernière synchro avec le dernier jour traité
      final newLastSync = pending.last;
      await box.put(_lastSyncKey, newLastSync.millisecondsSinceEpoch);

      _log.info(
          'Synced ${entries.length} day(s) of steps. Last sync: $newLastSync');
    } catch (e, s) {
      _log.severe('Failed to sync daily steps: $e', e, s);
    }
  }
}
