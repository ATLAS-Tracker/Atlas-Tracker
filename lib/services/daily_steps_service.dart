import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStepsService {
  DailyStepsService(
    SupabaseClient supabaseClient, {
    Health? health,
  })  : _supabaseClient = supabaseClient,
        _health = health ?? Health();

  final SupabaseClient _supabaseClient;
  final Health _health;
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

      final steps =
          await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

      await _syncStepsToSupabase(startOfDay, steps);
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

  Future<void> _syncStepsToSupabase(DateTime date, int steps) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      _log.fine('No authenticated user, skip Supabase sync');
      return;
    }

    final payload = {
      'user_id': userId,
      'date': DateTime.utc(date.year, date.month, date.day)
          .toIso8601String(),
      'steps': steps,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _supabaseClient
          .from('daily_steps')
          .upsert(payload, onConflict: 'user_id,date');
    } catch (error, stackTrace) {
      _log.warning('Failed to sync steps to Supabase', error, stackTrace);
    }
  }
}
