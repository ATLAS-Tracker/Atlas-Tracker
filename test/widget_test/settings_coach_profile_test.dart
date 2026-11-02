import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockProfileBloc extends Mock implements ProfileBloc {}

class MockHomeBloc extends Mock implements HomeBloc {}

class MockDiaryBloc extends Mock implements DiaryBloc {}

void main() {
  tearDown(() => locator.reset());

  for (final role in UserRoleEntity.values) {
    testWidgets('coach profile entry in settings, role=$role', (tester) async {
      final settings = MockSettingsBloc();
      when(() => settings.state).thenReturn(const SettingsLoadedState(
          '1.0.0', false, AppThemeEntity.system, false));
      when(() => settings.stream)
          .thenAnswer((_) => const Stream<SettingsState>.empty());
      final profile = MockProfileBloc();
      when(() => profile.state).thenReturn(ProfileLoadedState(
          userBMI: const UserBMIEntity(
              bmiValue: 24,
              nutritionalStatus: UserNutritionalStatus.normalWeight),
          userEntity: UserEntity(
              name: 'Alex',
              birthday: DateTime(1990),
              heightCM: 180,
              weightKG: 78,
              gender: UserGenderEntity.male,
              goal: UserWeightGoalEntity.maintainWeight,
              pal: UserPALEntity.active,
              role: role),
          usesImperialUnits: false));
      when(() => profile.stream)
          .thenAnswer((_) => const Stream<ProfileState>.empty());
      locator
        ..registerSingleton<SettingsBloc>(settings)
        ..registerSingleton<ProfileBloc>(profile)
        ..registerSingleton<HomeBloc>(MockHomeBloc())
        ..registerSingleton<DiaryBloc>(MockDiaryBloc());

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: const SettingsScreen(),
      ));
      await tester.pump();

      expect(find.text('Profil'),
          role == UserRoleEntity.coach ? findsOneWidget : findsNothing);
    });
  }
}
