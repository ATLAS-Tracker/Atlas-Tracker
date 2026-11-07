import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/entity/weight_snapshot.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import '../fixture/user_entity_fixtures.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';

class MockGetIntakeUsecase extends Mock implements GetIntakeUsecase {}

class MockDeleteIntakeUsecase extends Mock implements DeleteIntakeUsecase {}

class MockUpdateIntakeUsecase extends Mock implements UpdateIntakeUsecase {}

class MockGetUserActivityUsecase extends Mock
    implements GetUserActivityUsecase {}

class MockDeleteUserActivityUsecase extends Mock
    implements DeleteUserActivityUsecase {}

class MockAddTrackedDayUsecase extends Mock implements AddTrackedDayUsecase {}

class MockGetKcalGoalUsecase extends Mock implements GetKcalGoalUsecase {}

class MockGetMacroGoalUsecase extends Mock implements GetMacroGoalUsecase {}

class MockGetWeightUsecase extends Mock implements GetWeightUsecase {}

class MockDeleteUserWeightUsecase extends Mock
    implements DeleteUserWeightUsecase {}

class MockGetUserUsecase extends Mock implements GetUserUsecase {}

class MockAuth extends Mock implements GoTrueClient {}

class MockClient extends Mock implements SupabaseClient {}

void main() {
  late HomeBloc bloc;
  late MockClient client;
  late MockAuth auth;
  late SupabaseClient transport;
  late MockSupabaseHttpClient http;
  User user(String id) => User(
      id: id,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01');

  setUp(() async {
    registerFallbackValue(DateTime(2026));
    http = MockSupabaseHttpClient();
    transport = SupabaseClient('https://mock.invalid', 'key', httpClient: http);
    await transport.from('users').insert([
      {'id': 'student', 'coach_id': 'coach'},
      {'id': 'other', 'coach_id': 'other-coach'},
      {'id': 'coach', 'display_name': 'Coach'},
      {'id': 'other-coach', 'display_name': 'Other coach'},
    ]);
    auth = MockAuth();
    when(() => auth.currentUser).thenReturn(user('student'));
    client = MockClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.from(any())).thenAnswer(
        (call) => transport.from(call.positionalArguments.single as String));
    locator.registerSingleton<SupabaseClient>(client);
    final getUser = MockGetUserUsecase();
    when(() => getUser.getUserData()).thenAnswer((_) async =>
        UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight);
    locator.registerSingleton<GetUserUsecase>(getUser);
    final intakes = MockGetIntakeUsecase();
    when(() => intakes.getTodayBreakfastIntake()).thenAnswer((_) async => []);
    when(() => intakes.getTodayLunchIntake()).thenAnswer((_) async => []);
    when(() => intakes.getTodayDinnerIntake()).thenAnswer((_) async => []);
    when(() => intakes.getTodaySnackIntake()).thenAnswer((_) async => []);
    final activities = MockGetUserActivityUsecase();
    when(() => activities.getTodayUserActivity()).thenAnswer((_) async => []);
    final kcal = MockGetKcalGoalUsecase();
    when(() => kcal.getKcalGoal()).thenAnswer((_) async => 2000);
    final macros = MockGetMacroGoalUsecase();
    when(() => macros.getCarbsGoal()).thenAnswer((_) async => 250);
    when(() => macros.getFatsGoal()).thenAnswer((_) async => 60);
    when(() => macros.getProteinsGoal()).thenAnswer((_) async => 120);
    final weights = MockGetWeightUsecase();
    when(() => weights.getSnapshot(any()))
        .thenAnswer((_) async => const WeightSnapshot(null, null));
    bloc = HomeBloc(
        intakes,
        MockDeleteIntakeUsecase(),
        MockUpdateIntakeUsecase(),
        activities,
        MockDeleteUserActivityUsecase(),
        MockAddTrackedDayUsecase(),
        kcal,
        macros,
        weights,
        MockDeleteUserWeightUsecase());
  });
  tearDown(() async {
    await bloc.close();
    await locator.reset();
    await transport.dispose();
    http.close();
  });
  Future<HomeLoadedState> load() async {
    final loaded = bloc.stream.firstWhere((state) => state is HomeLoadedState);
    bloc.add(const LoadItemsEvent());
    return await loaded.timeout(const Duration(seconds: 3)) as HomeLoadedState;
  }

  test('coach queries run once per account across journal refreshes', () async {
    expect((await load()).coachName, 'Coach');
    expect((await load()).coachName, 'Coach');
    verify(() => client.from('users')).called(2);
    when(() => auth.currentUser).thenReturn(user('other'));
    expect((await load()).coachName, 'Other coach');
    verify(() => client.from('users')).called(2);
  });
  test('failed coach lookup is retried on the next refresh', () async {
    when(() => client.from('users')).thenThrow(StateError('offline'));
    expect((await load()).coachName, isNull);
    when(() => client.from('users')).thenAnswer((_) => transport.from('users'));
    expect((await load()).coachName, 'Coach');
    expect((await load()).coachName, 'Coach');
    verify(() => client.from('users')).called(3);
  });
  test('a successful lookup without a coach is cached', () async {
    when(() => auth.currentUser).thenReturn(user('unknown'));
    expect((await load()).coachName, isNull);
    expect((await load()).coachName, isNull);
    verify(() => client.from('users')).called(1);
  });
}
