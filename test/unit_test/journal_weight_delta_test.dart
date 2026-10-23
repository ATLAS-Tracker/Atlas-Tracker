import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';

class MockGetUserActivityUsecase extends Mock
    implements GetUserActivityUsecase {}

class MockGetIntakeUsecase extends Mock implements GetIntakeUsecase {}

class MockDeleteIntakeUsecase extends Mock implements DeleteIntakeUsecase {}

class MockDeleteUserActivityUsecase extends Mock
    implements DeleteUserActivityUsecase {}

class MockDeleteUserWeightUsecase extends Mock
    implements DeleteUserWeightUsecase {}

class MockGetTrackedDayUsecase extends Mock implements GetTrackedDayUsecase {}

class MockAddTrackedDayUsecase extends Mock implements AddTrackedDayUsecase {}

class MockGetWeightUsecase extends Mock implements GetWeightUsecase {}

class MockUpdateIntakeUsecase extends Mock implements UpdateIntakeUsecase {}

void main() {
  for (final hasHistory in [false, true]) {
    test('journal weight delta uses selected day history, history=$hasHistory',
        () async {
      final day = DateTime(2026, 10, 10);
      final activities = MockGetUserActivityUsecase();
      final intakes = MockGetIntakeUsecase();
      final tracked = MockGetTrackedDayUsecase();
      final weights = MockGetWeightUsecase();
      when(() => activities.getUserActivityByDay(day))
          .thenAnswer((_) async => []);
      when(() => intakes.getBreakfastIntakeByDay(day))
          .thenAnswer((_) async => []);
      when(() => intakes.getLunchIntakeByDay(day)).thenAnswer((_) async => []);
      when(() => intakes.getDinnerIntakeByDay(day)).thenAnswer((_) async => []);
      when(() => intakes.getSnackIntakeByDay(day)).thenAnswer((_) async => []);
      when(() => tracked.getTrackedDay(day)).thenAnswer((_) async => null);
      when(() => weights.getUserWeightByDate(day)).thenAnswer(
          (_) async => UserWeightEntity(id: 'today', weight: 78, date: day));
      when(() => weights.getWeightsFromPastDays(day, 7))
          .thenAnswer((_) async => hasHistory
              ? [
                  UserWeightEntity(
                      id: 'one',
                      weight: 79,
                      date: day.subtract(const Duration(days: 1))),
                  UserWeightEntity(
                      id: 'two',
                      weight: 80,
                      date: day.subtract(const Duration(days: 6))),
                ]
              : []);
      final bloc = CalendarDayBloc(
          activities,
          intakes,
          MockDeleteIntakeUsecase(),
          MockDeleteUserActivityUsecase(),
          MockDeleteUserWeightUsecase(),
          tracked,
          MockAddTrackedDayUsecase(),
          weights,
          MockUpdateIntakeUsecase());
      final loaded =
          bloc.stream.firstWhere((state) => state is CalendarDayLoaded);
      bloc.add(LoadCalendarDayEvent(day));
      final state = await loaded as CalendarDayLoaded;
      expect(state.weeklyWeightDelta, hasHistory ? -1.5 : null);
      verify(() => weights.getWeightsFromPastDays(day, 7)).called(1);
      await bloc.close();
    });
  }
}
