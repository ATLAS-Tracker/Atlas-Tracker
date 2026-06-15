import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetConfigUsecase _getConfigUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final UpdateIntakeUsecase _updateIntakeUsecase;
  final GetUserActivityUsecase _getUserActivityUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUseCase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final GetWeightUsecase _getWeightUsecase;
  final DeleteUserWeightUsecase _deleteUserWeightUsecase;
  final GetUserUsecase _getUserUsecase = locator<GetUserUsecase>();
  final SupabaseClient _supabaseClient = locator<SupabaseClient>();

  DateTime currentDay = DateTime.now();

  HomeBloc(
      this._getConfigUsecase,
      this._getIntakeUsecase,
      this._deleteIntakeUsecase,
      this._updateIntakeUsecase,
      this._getUserActivityUsecase,
      this._deleteUserActivityUsecase,
      this._addTrackedDayUseCase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase,
      this._getWeightUsecase,
      this._deleteUserWeightUsecase)
      : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      currentDay = DateTime.now();
      final configData = await _getConfigUsecase.getConfig();
      final usesImperialUnits = configData.usesImperialUnits;

      final breakfastIntakeList =
          await _getIntakeUsecase.getTodayBreakfastIntake();
      final totalBreakfastKcal = getTotalKcal(breakfastIntakeList);
      final totalBreakfastCarbs = getTotalCarbs(breakfastIntakeList);
      final totalBreakfastFats = getTotalFats(breakfastIntakeList);
      final totalBreakfastProteins = getTotalProteins(breakfastIntakeList);

      final lunchIntakeList = await _getIntakeUsecase.getTodayLunchIntake();
      final totalLunchKcal = getTotalKcal(lunchIntakeList);
      final totalLunchCarbs = getTotalCarbs(lunchIntakeList);
      final totalLunchFats = getTotalFats(lunchIntakeList);
      final totalLunchProteins = getTotalProteins(lunchIntakeList);

      final dinnerIntakeList = await _getIntakeUsecase.getTodayDinnerIntake();
      final totalDinnerKcal = getTotalKcal(dinnerIntakeList);
      final totalDinnerCarbs = getTotalCarbs(dinnerIntakeList);
      final totalDinnerFats = getTotalFats(dinnerIntakeList);
      final totalDinnerProteins = getTotalProteins(dinnerIntakeList);

      final snackIntakeList = await _getIntakeUsecase.getTodaySnackIntake();
      final totalSnackKcal = getTotalKcal(snackIntakeList);
      final totalSnackCarbs = getTotalCarbs(snackIntakeList);
      final totalSnackFats = getTotalFats(snackIntakeList);
      final totalSnackProteins = getTotalProteins(snackIntakeList);

      final totalKcalIntake = totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;
      final totalCarbsIntake = totalBreakfastCarbs +
          totalLunchCarbs +
          totalDinnerCarbs +
          totalSnackCarbs;
      final totalFatsIntake = totalBreakfastFats +
          totalLunchFats +
          totalDinnerFats +
          totalSnackFats;
      final totalProteinsIntake = totalBreakfastProteins +
          totalLunchProteins +
          totalDinnerProteins +
          totalSnackProteins;

      final userActivities =
          await _getUserActivityUsecase.getTodayUserActivity();
      final totalKcalActivities =
          userActivities.map((activity) => activity.burnedKcal).toList().sum;

      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal();
      final totalFatsGoal = await _getMacroGoalUsecase.getFatsGoal();
      final totalProteinsGoal = await _getMacroGoalUsecase.getProteinsGoal();

      final totalKcalLeft =
          CalorieGoalCalc.getDailyKcalLeft(totalKcalGoal, totalKcalIntake);

      final userWeight = await _getWeightUsecase.getTodayUserWeight();
      final weeklyWeightDelta = await _getWeeklyWeightDelta(userWeight);
      final userData = await _getUserUsecase.getUserData();
      final coachName = await _getCoachName();

      emit(HomeLoadedState(
          userName: userData.name,
          coachName: coachName,
          totalKcalDaily: totalKcalGoal,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalIntake,
          totalKcalBurned: totalKcalActivities,
          totalCarbsIntake: totalCarbsIntake,
          totalFatsIntake: totalFatsIntake,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
          totalProteinsIntake: totalProteinsIntake,
          breakfastIntakeList: breakfastIntakeList,
          lunchIntakeList: lunchIntakeList,
          dinnerIntakeList: dinnerIntakeList,
          snackIntakeList: snackIntakeList,
          userActivityList: userActivities,
          usesImperialUnits: usesImperialUnits,
          weeklyWeightDelta: weeklyWeightDelta,
          targetWeight: userData.weightKG,
          userWeightGoal: userData.goal,
          userWeightEntity: userWeight));
    });
  }

  Future<String?> _getCoachName() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    try {
      final userRows = await _supabaseClient
          .from('users')
          .select('coach_id')
          .eq('id', userId)
          .limit(1);

      if (userRows.isEmpty) {
        return null;
      }

      final coachId = userRows.first['coach_id']?.toString();
      if (coachId == null || coachId.isEmpty) {
        return null;
      }

      final coachRows = await _supabaseClient
          .from('users')
          .select('display_name')
          .eq('id', coachId)
          .limit(1);

      if (coachRows.isEmpty) {
        return null;
      }

      return (coachRows.first['display_name'] as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<double?> _getWeeklyWeightDelta(UserWeightEntity? currentWeight) async {
    if (currentWeight == null) {
      return null;
    }

    final pastWeights = await _getWeightUsecase.getWeightsFromPastDays(
      DateTime.now(),
      7,
    );

    if (pastWeights.isEmpty) {
      return null;
    }

    final averageWeight =
        pastWeights.map((weight) => weight.weight).toList().sum /
            pastWeights.length;

    return currentWeight.weight - averageWeight;
  }

  double getTotalKcal(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalKcal).toList().sum;

  double getTotalCarbs(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalCarbsGram).toList().sum;

  double getTotalFats(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalFatsGram).toList().sum;

  double getTotalProteins(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalProteinsGram).toList().sum;

  Future<void> updateIntakeItem(
      String intakeId, Map<String, dynamic> fields) async {
    final dateTime = DateTime.now();
    // Get old intake values
    final oldIntakeObject = await _getIntakeUsecase.getIntakeById(intakeId);
    assert(oldIntakeObject != null);
    final newIntakeObject =
        await _updateIntakeUsecase.updateIntake(intakeId, fields);
    assert(newIntakeObject != null);
    if (oldIntakeObject!.amount > newIntakeObject!.amount) {
      // Amounts shrunk
      await _addTrackedDayUseCase.removeDayCaloriesTracked(
          dateTime, oldIntakeObject.totalKcal - newIntakeObject.totalKcal);
      await _addTrackedDayUseCase.removeDayMacrosTracked(dateTime,
          carbsTracked:
              oldIntakeObject.totalCarbsGram - newIntakeObject.totalCarbsGram,
          fatTracked:
              oldIntakeObject.totalFatsGram - newIntakeObject.totalFatsGram,
          proteinTracked: oldIntakeObject.totalProteinsGram -
              newIntakeObject.totalProteinsGram);
    } else if (newIntakeObject.amount > oldIntakeObject.amount) {
      // Amounts gained
      await _addTrackedDayUseCase.addDayCaloriesTracked(
          dateTime, newIntakeObject.totalKcal - oldIntakeObject.totalKcal);
      await _addTrackedDayUseCase.addDayMacrosTracked(dateTime,
          carbsTracked:
              newIntakeObject.totalCarbsGram - oldIntakeObject.totalCarbsGram,
          fatTracked:
              newIntakeObject.totalFatsGram - oldIntakeObject.totalFatsGram,
          proteinTracked: newIntakeObject.totalProteinsGram -
              oldIntakeObject.totalProteinsGram);
    }
    _updateDiaryPage(dateTime);
  }

  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) async {
    final dateTime = DateTime.now();
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUseCase.removeDayCaloriesTracked(
        dateTime, intakeEntity.totalKcal);
    await _addTrackedDayUseCase.removeDayMacrosTracked(dateTime,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);

    _updateDiaryPage(dateTime);
  }

  Future<void> deleteUserWeightItem() async {
    await _deleteUserWeightUsecase.deleteTodayUserWeight();
    _updateDiaryPage(DateTime.now());
  }

  Future<void> deleteUserActivityItem(UserActivityEntity activityEntity) async {
    final dateTime = DateTime.now();
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUseCase.reduceDayCalorieGoal(
        dateTime, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount =
        MacroCalc.getTotalProteinsGoal(activityEntity.burnedKcal);

    _addTrackedDayUseCase.reduceDayMacroGoals(dateTime,
        carbsAmount: carbsAmount,
        fatAmount: fatAmount,
        proteinAmount: proteinAmount);
    await _addTrackedDayUseCase.removeDayCaloriesBurned(
        dateTime, activityEntity.burnedKcal);
    _updateDiaryPage(dateTime);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }
}
