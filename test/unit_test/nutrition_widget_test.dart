import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/common_config_dbo.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/macro_goal_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/services/nutrition_widget_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockHive extends Mock implements HiveDBProvider {}

class MockClient extends Mock implements SupabaseClient {}

class MockAuth extends Mock implements GoTrueClient {}

class MockGoals extends Mock implements MacroGoalRepository {}

class MockConfig extends Mock implements ConfigRepository {}

class MockIntakeBox extends Mock implements Box<IntakeDBO> {}

class MockMacroBox extends Mock implements Box<MacroGoalDbo> {}

class MockCommonConfigBox extends Mock implements Box<CommonConfigDBO> {}

IntakeEntity intake(DateTime date, {double portions = 1}) => IntakeEntity(
    id: date.toIso8601String(),
    unit: 'serving',
    amount: portions,
    type: IntakeTypeEntity.lunch,
    dateTime: date,
    meal: const MealEntity(
      code: 'food',
      name: 'Food',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: 40,
      servingUnit: 'g',
      servingSize: '40 g',
      nutriments: MealNutrimentsEntity(
        energyKcalPerQuantity: 250,
        carbohydratesPerQuantity: 30,
        fatPerQuantity: 10,
        proteinsPerQuantity: 10,
        sugarsPerQuantity: null,
        saturatedFatPerQuantity: null,
        fiberPerQuantity: null,
        mealOrRecipe: MealOrRecipeEntity.meal,
      ),
      source: MealSourceEntity.custom,
    ));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 11, 9);

  test(
      'counts all meals of today using serving quantities, excludes other days',
      () {
    final data =
        nutritionWidgetData(day: day, goal: null, theme: 'dark', intakes: [
      intake(DateTime(2026, 11, 8, 23, 59), portions: 100),
      intake(day, portions: 2),
      intake(DateTime(2026, 11, 9, 23, 59)),
      intake(DateTime(2026, 11, 10), portions: 100),
    ]);
    expect(data['date'], '2026-11-09');
    expect(data['kcal'], 300);
    expect(data['carbs'], 36);
    expect(data['proteins'], 12);
    expect(data['fats'], 12);
    expect(data['theme'], 'dark');
    expect(data['kcalGoal'], 2020);
  });

  test(
      'uses the effective macro goals, including a scheduled change at midnight',
      () {
    final goal = MacroGoalEntity(
        id: 'owner',
        date: day,
        oldCarbsGoal: 200,
        oldFatsGoal: 50,
        oldProteinsGoal: 100,
        newCarbsGoal: 300,
        newFatsGoal: 70,
        newProteinsGoal: 150);
    final before = nutritionWidgetData(
        day: DateTime(2026, 11, 8), goal: goal, intakes: [], theme: 'system');
    final after =
        nutritionWidgetData(day: day, goal: goal, intakes: [], theme: 'system');
    expect(before['kcalGoal'], 1650);
    expect(after['kcalGoal'], 2430);
    expect(after['carbsGoal'], 300);
    expect(after['proteinsGoal'], 150);
    expect(after['fatsGoal'], 70);
    expect(after['kcal'], 0);
  });

  group('platform publication', () {
    late MockHive hive;
    late MockClient client;
    late MockAuth auth;
    late MockGoals goals;
    late MockConfig config;
    late NutritionWidgetService service;
    final calls = <MethodCall>[];
    final user = User(
        id: 'owner',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01');

    setUp(() {
      hive = MockHive();
      client = MockClient();
      auth = MockAuth();
      goals = MockGoals();
      config = MockConfig();
      when(() => client.auth).thenReturn(auth);
      when(() => hive.activeUserId).thenReturn('owner');
      when(() => auth.currentUser).thenReturn(user);
      when(() => goals.getMacroGoal()).thenAnswer((_) async => null);
      when(() => config.getConfigAppTheme())
          .thenAnswer((_) async => AppThemeEntity.light);
      service = NutritionWidgetService(hive, client, goals, config);
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NutritionWidgetService.channel,
              (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() async {
      await service.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NutritionWidgetService.channel, null);
    });

    test('publishes current totals again after additions, edits and deletions',
        () async {
      final box = MockIntakeBox();
      when(() => hive.intakeBox).thenReturn(box);
      when(() => box.isOpen).thenReturn(true);
      final entry = intake(DateTime.now());
      when(() => box.values).thenReturn([IntakeDBO.fromIntakeEntity(entry)]);
      await service.refresh();
      expect(calls.last.arguments['kcal'], 100);
      when(() => box.values).thenReturn([
        IntakeDBO.fromIntakeEntity(entry.copyWith(amount: 3)),
      ]);
      await service.refresh();
      expect(calls.last.arguments['kcal'], 300);
      when(() => box.values).thenReturn([]);
      await service.refresh();
      expect(calls.last.arguments['kcal'], 0);
    });

    test('clears cached nutrition on logout without reading private boxes',
        () async {
      when(() => auth.currentUser).thenReturn(null);
      await service.refresh();
      expect(calls.single.method, 'update');
      expect(calls.single.arguments, isNull);
      verifyNever(() => goals.getMacroGoal());
      verifyNever(() => hive.intakeBox);
    });

    test('a journal mutation automatically refreshes the home widget',
        () async {
      final changes = StreamController<BoxEvent>.broadcast();
      final box = MockIntakeBox();
      final macroBox = MockMacroBox();
      final commonBox = MockCommonConfigBox();
      when(() => hive.intakeBox).thenReturn(box);
      when(() => hive.macroGoalBox).thenReturn(macroBox);
      when(() => hive.commonConfigBox).thenReturn(commonBox);
      when(() => box.isOpen).thenReturn(true);
      when(() => box.values).thenReturn([]);
      when(() => box.watch()).thenAnswer((_) => changes.stream);
      when(() => macroBox.watch()).thenAnswer((_) => const Stream.empty());
      when(() => commonBox.watch()).thenAnswer((_) => const Stream.empty());
      when(() => auth.onAuthStateChange)
          .thenAnswer((_) => const Stream.empty());
      service.start();
      await Future<void>.delayed(Duration.zero);
      expect(calls.last.arguments['kcal'], 0);
      when(() => box.values)
          .thenReturn([IntakeDBO.fromIntakeEntity(intake(DateTime.now()))]);
      changes.add(BoxEvent('meal', null, false));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(calls.last.arguments['kcal'], 100);
      await service.dispose();
      await changes.close();
    });

    test('an in-flight read cannot republish the old account after logout',
        () async {
      final pending = Completer<MacroGoalEntity?>();
      when(() => goals.getMacroGoal()).thenAnswer((_) => pending.future);
      final first = service.refresh();
      when(() => auth.currentUser).thenReturn(null);
      await service.refresh();
      pending.complete(null);
      await first;
      expect(calls, hasLength(1));
      expect(calls.single.arguments, isNull);
    });
  });
}
