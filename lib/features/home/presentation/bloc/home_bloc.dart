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
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
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
  String? _coachNameUserId;
  Future<String?>? _coachNameFuture;

  HomeBloc(
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
      try {
        currentDay = DateTime.now();

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

        final weightSnapshot = await _getWeightUsecase.getSnapshot(currentDay);
        final userWeight = weightSnapshot.current;
        final weeklyWeightDelta = weightSnapshot.delta;
        final userData = await _getUserUsecase.getUserData();
        final coachName = await _getCoachName();

        emit(HomeLoadedState(
            userName: userData.name,
            coachName: coachName,
            totalKcalDaily: totalKcalGoal,
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
            weeklyWeightDelta: weeklyWeightDelta,
            userWeightGoal: userData.goal,
            userWeightEntity: userWeight));
      } catch (_) {
        emit(HomeErrorState());
      }
    });
  }

  Future<String?> _getCoachName() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != _coachNameUserId) {
      _coachNameUserId = userId;
      _coachNameFuture = null;
    }
    if (userId == null) return null;
    try {
      return await (_coachNameFuture ??= _loadCoachName(userId));
    } catch (_) {
      if (_coachNameUserId == userId) _coachNameFuture = null;
      return null;
    }
  }

  Future<String?> _loadCoachName(String userId) async {
    final userRows = await _supabaseClient
        .from('users')
        .select('coach_id')
        .eq('id', userId)
        .limit(1)
        .timeout(const Duration(seconds: 5));

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
        .limit(1)
        .timeout(const Duration(seconds: 5));

    if (coachRows.isEmpty) {
      return null;
    }

    return (coachRows.first['display_name'] as String?)?.trim();
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
    final intake = await _updateIntakeUsecase.updateIntake(intakeId, fields);
    if (intake != null) await _updateDiaryPage(intake.dateTime);
  }

  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _updateDiaryPage(intakeEntity.dateTime);
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
