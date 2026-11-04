import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

Future<void> saveCoachMacroGoal(
  SupabaseClient client, {
  required String studentId,
  required DateTime startDate,
  required int carbs,
  required int fat,
  required int protein,
}) async {
  final calories = carbs * 4 + fat * 9 + protein * 4;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(startDate.year, startDate.month, startDate.day);
  if (studentId.isEmpty ||
      [carbs, fat, protein].any((value) => value < 0 || value > 1000) ||
      calories <= 0 ||
      calories > 10000 ||
      day.isBefore(today) ||
      day.isAfter(today.add(const Duration(days: 730)))) {
    throw ArgumentError('Invalid coach goal');
  }
  try {
    await client.rpc('atlas_set_macro_goal', params: {
      'p_user_id': studentId,
      'p_start_date': day.toDayKey(),
      'p_carb_goal': carbs,
      'p_fat_goal': fat,
      'p_protein_goal': protein,
    }).timeout(const Duration(seconds: 8));
    return;
  } on PostgrestException catch (error) {
    if (error.code != 'PGRST202') rethrow;
  }
  // Only a missing RPC permits the deployed route; authorization errors do not.
  await client.from('coach_macro_goals').upsert({
    'user_id': studentId,
    'start_date': day.toDayKey(),
    'calorie_goal': calories,
    'carb_goal': carbs,
    'fat_goal': fat,
    'protein_goal': protein,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  }, onConflict: 'user_id').timeout(const Duration(seconds: 8));
}
