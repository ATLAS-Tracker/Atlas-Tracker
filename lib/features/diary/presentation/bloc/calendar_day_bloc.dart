import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

part 'calendar_day_event.dart';

part 'calendar_day_state.dart';

class CalendarDayBloc extends Bloc<CalendarDayEvent, CalendarDayState> {
  final GetUserActivityUsecase _getUserActivityUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetWeightUsecase _getUserWeightUsecase;
  final DeleteUserWeightUsecase _deleteUserWeightUsecase;
  final UpdateIntakeUsecase _updateIntakeUsecase;

  DateTime? _currentDay;

  CalendarDayBloc(
      this._getUserActivityUsecase,
      this._getIntakeUsecase,
      this._deleteIntakeUsecase,
      this._deleteUserActivityUsecase,
      this._deleteUserWeightUsecase,
      this._getTrackedDayUsecase,
      this._addTrackedDayUsecase,
      this._getUserWeightUsecase,
      this._updateIntakeUsecase)
      : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      _currentDay = event.day;
      await _loadCalendarDay(event.day, emit);
    });

    on<RefreshCalendarDayEvent>((event, emit) async {
      if (_currentDay != null) {
        emit(CalendarDayLoading());
        await _loadCalendarDay(_currentDay!, emit);
      }
    });
  }

  Future<void> _loadCalendarDay(
      DateTime day, Emitter<CalendarDayState> emit) async {
    try {
      final userActivities =
          await _getUserActivityUsecase.getUserActivityByDay(day);

      final breakfastIntakeList =
          await _getIntakeUsecase.getBreakfastIntakeByDay(day);

      final lunchIntakeList = await _getIntakeUsecase.getLunchIntakeByDay(day);
      final dinnerIntakeList =
          await _getIntakeUsecase.getDinnerIntakeByDay(day);
      final snackIntakeList = await _getIntakeUsecase.getSnackIntakeByDay(day);

      final storedDay = await _getTrackedDayUsecase.getTrackedDay(day);
      final intakes = [
        ...breakfastIntakeList,
        ...lunchIntakeList,
        ...dinnerIntakeList,
        ...snackIntakeList,
      ];
      final goals = locator<GetMacroGoalUsecase>();
      final carbs = await goals.getCarbsGoal(day: day);
      final fats = await goals.getFatsGoal(day: day);
      final proteins = await goals.getProteinsGoal(day: day);
      // Like HomeBloc: calculate consumption from each food and its quantity.
      final trackedDayEntity = TrackedDayEntity(
        day: day,
        calorieGoal: carbs * 4 + fats * 9 + proteins * 4,
        carbsGoal: carbs,
        fatGoal: fats,
        proteinGoal: proteins,
        caloriesTracked:
            intakes.fold<double>(0, (sum, food) => sum + food.totalKcal),
        carbsTracked:
            intakes.fold<double>(0, (sum, food) => sum + food.totalCarbsGram),
        fatTracked:
            intakes.fold<double>(0, (sum, food) => sum + food.totalFatsGram),
        proteinTracked: intakes.fold<double>(
            0, (sum, food) => sum + food.totalProteinsGram),
        caloriesBurned: storedDay?.caloriesBurned ?? 0,
        updatedAt: storedDay?.updatedAt,
      );

      final weightSnapshot = await _getUserWeightUsecase.getSnapshot(day);
      final userWeightEntity = weightSnapshot.current;
      final weeklyWeightDelta = weightSnapshot.delta;

      emit(CalendarDayLoaded(
          trackedDayEntity,
          userActivities,
          breakfastIntakeList,
          lunchIntakeList,
          dinnerIntakeList,
          snackIntakeList,
          userWeightEntity,
          weeklyWeightDelta: weeklyWeightDelta));
    } catch (_) {
      emit(CalendarDayError());
    }
  }

  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
  }

  Future<void> updateIntakeItem(
      String intakeId, Map<String, dynamic> fields) async {
    await _updateIntakeUsecase.updateIntake(intakeId, fields);
  }

  Future<void> deleteUserWeightItem(DateTime day) async {
    await _deleteUserWeightUsecase.deleteUserWeightByDate(day);
    _updateDiaryPage(day);
  }

  Future<void> deleteUserActivityItem(
      UserActivityEntity activityEntity, DateTime day) async {
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUsecase.reduceDayCalorieGoal(day, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount =
        MacroCalc.getTotalProteinsGoal(activityEntity.burnedKcal);

    _addTrackedDayUsecase.reduceDayMacroGoals(day,
        carbsAmount: carbsAmount,
        fatAmount: fatAmount,
        proteinAmount: proteinAmount);
    await _addTrackedDayUsecase.removeDayCaloriesBurned(
        day, activityEntity.burnedKcal);
    _updateDiaryPage(day);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(day));
  }
}
