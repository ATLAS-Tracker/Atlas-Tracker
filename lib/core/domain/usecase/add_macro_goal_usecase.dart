import 'package:opennutritracker/core/data/repository/macro_goal_repository.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class AddMacroGoalUsecase {
  final MacroGoalRepository _macroGoalRepository =
      locator<MacroGoalRepository>();
  final SupabaseClient _supabaseClient = locator<SupabaseClient>();
  final AddTrackedDayUsecase _addTrackedDayUsecase =
      locator<AddTrackedDayUsecase>();
  final GetTrackedDayUsecase _getTrackedDayUsecase =
      locator<GetTrackedDayUsecase>();

  Future<void> addMacroGoalFromCoach() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final responses = await Future.wait([
      _supabaseClient
          .from('coach_macro_goals')
          .select()
          .eq('user_id', userId)
          .lte('start_date', now.toDayKey())
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8)),
      _supabaseClient
          .from('coach_macro_goals')
          .select()
          .eq('user_id', userId)
          .gt('start_date', now.toDayKey())
          .order('start_date')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8)),
    ]);
    bool owns() =>
        _supabaseClient.auth.currentUser?.id == userId &&
        locator<HiveDBProvider>().activeUserId == userId;
    if (!owns()) return;
    final oldEntity = await _macroGoalRepository.getMacroGoal();
    final history = responses.whereType<Map<String, dynamic>>().toList();
    final newMacro = MacroGoalEntity.fromHistory(userId, history,
        today: now, previous: oldEntity);
    if (newMacro == null || !owns()) return;
    await _macroGoalRepository.saveMacroGoal(newMacro);
    final firstStart = history
        .map((row) => DateTime.tryParse(row['start_date'].toString()))
        .whereType<DateTime>()
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final existingDays = await _getTrackedDayUsecase.getTrackedDaysFrom(
      firstStart,
    );
    for (final day in existingDays) {
      if (!owns()) return;
      final goal = MacroGoalEntity.forDay(newMacro, day);
      await _addTrackedDayUsecase.updateDayCalorieGoal(
          day, goal.carbs * 4 + goal.fats * 9 + goal.proteins * 4);
      await _addTrackedDayUsecase.updateDayMacroGoals(
        day,
        carbsGoal: goal.carbs,
        fatGoal: goal.fats,
        proteinGoal: goal.proteins,
      );
    }
  }
}
