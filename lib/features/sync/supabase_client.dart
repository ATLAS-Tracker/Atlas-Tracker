import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class SupabaseDailyStepsService {
  final SupabaseClient _client;
  final _log = Logger('SupabaseDailyStepsService');

  SupabaseDailyStepsService({SupabaseClient? client})
      : _client = client ?? locator<SupabaseClient>();

  /// Upserts multiple daily step entries.
  /// If the list is empty, the function exits early.
  /// Logs any exception that occurs during the operation.
  Future<void> upsertDailySteps(List<Map<String, dynamic>> days) async {
    if (days.isEmpty) return;
    try {
      await _client
          .from('daily_steps')
          .upsert(days, onConflict: 'user_id,date');
    } catch (e, stackTrace) {
      _log.severe('Failed to upsert daily steps: $e', e, stackTrace);
    }
  }

  /// Fetches the step count for a given [userId] and [date].
  /// Returns `0` if no entry is found or an error occurs.
  Future<int> fetchDailySteps(String userId, DateTime date) async {
    try {
      final isoDate = date.toIso8601String().split('T').first;
      final data = await _client
          .from('daily_steps')
          .select('steps')
          .eq('user_id', userId)
          .eq('date', isoDate)
          .maybeSingle();
      return (data?['steps'] as int?) ?? 0;
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch daily steps: $e', e, stackTrace);
      return 0;
    }
  }
}
