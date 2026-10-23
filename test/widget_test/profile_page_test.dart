import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

class MockHomeBloc extends Mock implements HomeBloc {}

class MockHomeLoadedState extends Mock implements HomeLoadedState {}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });
  tearDown(() => locator.reset());

  for (final role in UserRoleEntity.values) {
    for (final dark in [false, true]) {
      testWidgets(
          'profile preserves role actions at narrow width, role=$role dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final user = UserEntity(
            name: 'Benjamin avec un nom de famille très long',
            birthday: DateTime(1990),
            heightCM: 180,
            weightKG: 78.4,
            gender: UserGenderEntity.male,
            goal: UserWeightGoalEntity.loseWeight,
            pal: UserPALEntity.active,
            role: role);
        final bloc = MockProfileBloc();
        when(() => bloc.state).thenReturn(ProfileLoadedState(
            userBMI: const UserBMIEntity(
                bmiValue: 24,
                nutritionalStatus: UserNutritionalStatus.normalWeight),
            userEntity: user,
            usesImperialUnits: false));
        when(() => bloc.stream)
            .thenAnswer((_) => const Stream<ProfileState>.empty());
        when(() => bloc.getDisplayWeight(user, false)).thenReturn('78.4');
        when(() => bloc.getDisplayHeight(user, false)).thenReturn('180');
        locator.registerSingleton<ProfileBloc>(bloc);
        final home = MockHomeBloc();
        final homeState = MockHomeLoadedState();
        when(() => homeState.coachName).thenReturn('Coach Alex');
        when(() => home.state).thenReturn(homeState);
        when(() => home.stream)
            .thenAnswer((_) => const Stream<HomeState>.empty());
        locator.registerSingleton<HomeBloc>(home);
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          theme: ThemeData(
              textTheme: appTextTheme,
              colorScheme: dark ? darkColorScheme : lightColorScheme),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          home: const Scaffold(body: ProfilePage()),
        ));
        await tester.pumpAndSettle();
        expect(find.text(user.name), findsOneWidget);
        expect(find.textContaining('Coach Alex'),
            role == UserRoleEntity.student ? findsOneWidget : findsNothing);
        expect(find.byIcon(Icons.north_east_rounded), findsNothing);
        if (role == UserRoleEntity.student) {
          expect(find.byIcon(Icons.group_outlined), findsNothing);
          await tester.ensureVisible(find.text(S.current.activityLabel));
          await tester.tap(find.text(S.current.activityLabel));
          await tester.pumpAndSettle();
          expect(find.byType(SetPALCategoryDialog), findsOneWidget);
          Navigator.of(tester.element(find.byType(SetPALCategoryDialog))).pop();
          await tester.pumpAndSettle();
        } else {
          expect(find.byIcon(Icons.group_outlined), findsOneWidget);
          expect(find.byIcon(Icons.directions_walk_outlined), findsNothing);
        }
        await tester.scrollUntilVisible(
            find.text(S.current.manageAccountTitle), 300);
        expect(find.text(S.current.manageAccountTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
