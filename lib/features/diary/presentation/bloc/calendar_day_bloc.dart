import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
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
    final userActivities =
        await _getUserActivityUsecase.getUserActivityByDay(day);

    final breakfastIntakeList =
        await _getIntakeUsecase.getBreakfastIntakeByDay(day);

    final lunchIntakeList = await _getIntakeUsecase.getLunchIntakeByDay(day);
    final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(day);
    final snackIntakeList = await _getIntakeUsecase.getSnackIntakeByDay(day);

    final trackedDayEntity = await _getTrackedDayUsecase.getTrackedDay(day);

    final userWeightEntity =
        await _getUserWeightUsecase.getUserWeightByDate(day);

    emit(CalendarDayLoaded(
        trackedDayEntity,
        userActivities,
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList,
        userWeightEntity));
  }

  Future<void> deleteIntakeItem(
      BuildContext context, IntakeEntity intakeEntity, DateTime day) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
        day, intakeEntity.totalKcal);
    await _addTrackedDayUsecase.removeDayMacrosTracked(day,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
  }

  Future<void> updateIntakeItem(
      String intakeId, Map<String, dynamic> fields, DateTime day) async {
    final oldIntakeObject = await _getIntakeUsecase.getIntakeById(intakeId);
    assert(oldIntakeObject != null);
    final newIntakeObject =
        await _updateIntakeUsecase.updateIntake(intakeId, fields);
    assert(newIntakeObject != null);

    if (oldIntakeObject == null || newIntakeObject == null) {
      return;
    }

    final kcalDelta = newIntakeObject.totalKcal - oldIntakeObject.totalKcal;
    final carbsDelta =
        newIntakeObject.totalCarbsGram - oldIntakeObject.totalCarbsGram;
    final fatsDelta =
        newIntakeObject.totalFatsGram - oldIntakeObject.totalFatsGram;
    final proteinsDelta =
        newIntakeObject.totalProteinsGram - oldIntakeObject.totalProteinsGram;

    if (kcalDelta > 0) {
      await _addTrackedDayUsecase.addDayCaloriesTracked(day, kcalDelta);
    } else if (kcalDelta < 0) {
      await _addTrackedDayUsecase.removeDayCaloriesTracked(
          day, kcalDelta.abs());
    }

    if (carbsDelta > 0 || fatsDelta > 0 || proteinsDelta > 0) {
      await _addTrackedDayUsecase.addDayMacrosTracked(
        day,
        carbsTracked: carbsDelta > 0 ? carbsDelta : 0,
        fatTracked: fatsDelta > 0 ? fatsDelta : 0,
        proteinTracked: proteinsDelta > 0 ? proteinsDelta : 0,
      );
    }

    if (carbsDelta < 0 || fatsDelta < 0 || proteinsDelta < 0) {
      await _addTrackedDayUsecase.removeDayMacrosTracked(
        day,
        carbsTracked: carbsDelta < 0 ? carbsDelta.abs() : 0,
        fatTracked: fatsDelta < 0 ? fatsDelta.abs() : 0,
        proteinTracked: proteinsDelta < 0 ? proteinsDelta.abs() : 0,
      );
    }
  }

  Future<void> deleteUserWeightItem(DateTime day) async {
    await _deleteUserWeightUsecase.deleteUserWeightByDate(day);
    _updateDiaryPage(day);
  }

  Future<void> deleteUserActivityItem(BuildContext context,
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
