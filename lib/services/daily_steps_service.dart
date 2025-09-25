import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:health/health.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/services/daily_steps_queue_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStepsService {
  DailyStepsService(
    SupabaseClient supabaseClient, {
    Health? health,
    Connectivity? connectivity,
    HiveDBProvider? hiveProvider,
  })  : _supabaseClient = supabaseClient,
        _health = health ?? Health(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        _hiveProvider = hiveProvider ?? locator<HiveDBProvider>();

  final SupabaseClient _supabaseClient;
  final Health _health;
  final Connectivity _connectivity;
  final HiveDBProvider _hiveProvider;
  final _log = Logger('DailyStepsService');

  bool _isConfigured = false;

  Future<int?> fetchAndSyncTodaySteps() async {
    try {
      await _ensureConfigured();

      if (!await _ensurePermissions()) {
        _log.warning('Steps permission not granted');
        return null;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final normalizedDate = _normalizeDate(startOfDay);

      final steps =
          await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

      if (await _hasConnectivity()) {
        await _flushQueuedSteps();
        try {
          await syncStepsToSupabase(normalizedDate, steps);
        } catch (error, stackTrace) {
          _log.warning('Immediate Supabase sync failed, queuing steps', error,
              stackTrace);
          await _queueSteps(normalizedDate, steps);
        }
      } else {
        _log.fine('No connectivity detected, queuing steps.');
        await _queueSteps(normalizedDate, steps);
      }
      return steps;
    } catch (error, stackTrace) {
      _log.severe('Failed to fetch and sync steps', error, stackTrace);
      return null;
    }
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;

    await _health.configure();
    _isConfigured = true;
  }

  Future<bool> _ensurePermissions() async {
    const types = [HealthDataType.STEPS];
    const permissions = [HealthDataAccess.READ];

    final hasPermissions =
        await _health.hasPermissions(types, permissions: permissions);

    if (hasPermissions == true) {
      return true;
    }

    final granted =
        await _health.requestAuthorization(types, permissions: permissions);
    return granted;
  }

  Future<void> syncStepsToSupabase(DateTime date, int steps) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      _log.fine('No authenticated user, skip Supabase sync');
      return;
    }

    final normalizedDate = _normalizeDate(date);
    final payload = {
      'user_id': userId,
      'date': normalizedDate.toIso8601String(),
      'steps': steps,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _supabaseClient
          .from('daily_steps')
          .upsert(payload, onConflict: 'user_id,date');
    } catch (error, stackTrace) {
      _log.warning('Failed to sync steps to Supabase', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _queueSteps(DateTime date, int steps) async {
    try {
      final box = _queueBoxOrNull();
      if (box == null) {
        _log.warning('Daily steps queue box unavailable, cannot queue entry.');
        return;
      }

      final entry = DailyStepsQueueEntry(
        date: _normalizeDate(date),
        steps: steps,
        queuedAt: DateTime.now().toUtc(),
      );

      await box.put(_queueKey(entry.date), entry);
      _log.info('Queued ${entry.steps} steps for ${entry.date}.');
    } catch (error, stackTrace) {
      _log.warning('Failed to queue steps locally', error, stackTrace);
    }
  }

  Future<void> _flushQueuedSteps() async {
    try {
      await _hiveProvider.triggerDailyStepsSync();
    } catch (error, stackTrace) {
      _log.warning('Failed to trigger queued steps sync', error, stackTrace);
    }
  }

  Future<bool> _hasConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Box<DailyStepsQueueEntry>? _queueBoxOrNull() {
    try {
      return _hiveProvider.dailyStepsQueueBox;
    } catch (_) {
      return null;
    }
  }

  String _queueKey(DateTime date) => _normalizeDate(date).toIso8601String();

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}
