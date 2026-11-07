import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/entity/weight_snapshot.dart';
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

class MockIntake extends Mock implements IntakeEntity {}

class MockGoals extends Mock implements GetMacroGoalUsecase {}

void main() {
  tearDown(() => locator.reset());
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
      final breakfast = MockIntake();
      final dinner = MockIntake();
      when(() => breakfast.totalKcal).thenReturn(1000);
      when(() => dinner.totalKcal).thenReturn(993);
      when(() => breakfast.totalCarbsGram).thenReturn(100);
      when(() => dinner.totalCarbsGram).thenReturn(120);
      when(() => breakfast.totalFatsGram).thenReturn(30);
      when(() => dinner.totalFatsGram).thenReturn(35);
      when(() => breakfast.totalProteinsGram).thenReturn(50);
      when(() => dinner.totalProteinsGram).thenReturn(70);
      when(() => intakes.getBreakfastIntakeByDay(day))
          .thenAnswer((_) async => [breakfast]);
      when(() => intakes.getLunchIntakeByDay(day)).thenAnswer((_) async => []);
      when(() => intakes.getDinnerIntakeByDay(day))
          .thenAnswer((_) async => [dinner]);
      when(() => intakes.getSnackIntakeByDay(day)).thenAnswer((_) async => []);
      final goals = MockGoals();
      locator.registerSingleton<GetMacroGoalUsecase>(goals);
      when(() => goals.getCarbsGoal(day: day)).thenAnswer((_) async => 250);
      when(() => goals.getFatsGoal(day: day)).thenAnswer((_) async => 89);
      when(() => goals.getProteinsGoal(day: day)).thenAnswer((_) async => 100);
      when(() => tracked.getTrackedDay(day)).thenAnswer((_) async =>
          TrackedDayEntity(day: day, calorieGoal: 1700, caloriesTracked: 2124));
      when(() => weights.getSnapshot(day))
          .thenAnswer((_) async => WeightSnapshot.at(day, [
                UserWeightEntity(id: 'today', weight: 78, date: day),
                if (hasHistory) ...[
                  UserWeightEntity(
                      id: 'one', weight: 79, date: DateTime(2026, 10, 9)),
                  UserWeightEntity(
                      id: 'two', weight: 80, date: DateTime(2026, 10, 4)),
                ],
              ]));
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
      expect(state.trackedDayEntity!.calorieGoal, 2201);
      expect(state.trackedDayEntity!.caloriesTracked, 1993);
      expect(state.trackedDayEntity!.carbsTracked, 220);
      expect(state.trackedDayEntity!.fatTracked, 65);
      expect(state.trackedDayEntity!.proteinTracked, 120);
      expect(state.weeklyWeightDelta, hasHistory ? -1.5 : null);
      verify(() => weights.getSnapshot(day)).called(1);
      await bloc.close();
    });
  }
}
