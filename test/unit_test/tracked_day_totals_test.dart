import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/data/tracked_day_totals.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

void main() {
  late Directory directory;
  late HiveDBProvider hive;
  late IntakeDataSource intakes;
  late TrackedDayDataSource days;
  final yesterday = DateTime(2026, 11, 2);
  final today = DateTime(2026, 11, 3);
  final oldTimestamp = DateTime.utc(2025);

  IntakeDBO food(String id, DateTime date, {double amount = 100}) => IntakeDBO(
        id: id,
        unit: 'g',
        amount: amount,
        type: IntakeTypeDBO.breakfast,
        dateTime: date,
        updatedAt: oldTimestamp,
        meal: MealDBO(
          code: id,
          name: 'Aliment test',
          brands: null,
          thumbnailImageUrl: null,
          mainImageUrl: null,
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: 30,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsDBO(
            energyKcalPerQuantity: 200,
            carbohydratesPerQuantity: 30,
            fatPerQuantity: 5,
            proteinsPerQuantity: 10,
            sugarsPerQuantity: null,
            saturatedFatPerQuantity: null,
            fiberPerQuantity: null,
            mealOrRecipe: MealOrRecipeDBO.meal,
          ),
          source: MealSourceDBO.custom,
        ),
      );

  TrackedDayDBO day(DateTime date) => TrackedDayDBO(
        day: date,
        calorieGoal: 2020,
        caloriesTracked: 2240,
        carbsGoal: 250,
        carbsTracked: 999,
        fatGoal: 60,
        fatTracked: 999,
        proteinGoal: 120,
        proteinTracked: 999,
        caloriesBurned: 150,
        updatedAt: oldTimestamp,
      );

  setUpAll(() {
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
    Hive.registerAdapter(MealDBOAdapter());
    Hive.registerAdapter(MealSourceDBOAdapter());
    Hive.registerAdapter(MealNutrimentsDBOAdapter());
    Hive.registerAdapter(MealOrRecipeDBOAdapter());
    Hive.registerAdapter(TrackedDayDBOAdapter());
    Hive.registerAdapter(MacroGoalDboAdapter());
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atlas_totals_');
    Hive.init(directory.path);
    hive = HiveDBProvider()
      ..macroGoalBox = await Hive.openBox<MacroGoalDbo>('goals')
      ..intakeBox = await Hive.openBox<IntakeDBO>('intakes')
      ..trackedDayBox = await Hive.openBox<TrackedDayDBO>('days');
    intakes = IntakeDataSource(hive);
    days = TrackedDayDataSource(hive);
    // Reproduce existing drift without going through the write under test.
    await hive.trackedDayBox.put(yesterday.toDayKey(), day(yesterday));
    await hive.trackedDayBox.put(today.toDayKey(), day(today));
    await hive.intakeBox.add(food('original', yesterday));
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  void expectYesterday(double kcal, double carbs, double fat, double protein) {
    final actual = hive.trackedDayBox.get(yesterday.toDayKey())!;
    expect(actual.caloriesTracked, kcal);
    expect(actual.carbsTracked, carbs);
    expect(actual.fatTracked, fat);
    expect(actual.proteinTracked, protein);
    expect(actual.calorieGoal, 2020);
    expect(actual.carbsGoal, 250);
    expect(actual.fatGoal, 60);
    expect(actual.proteinGoal, 120);
    expect(actual.caloriesBurned, 150);
    expect(actual.updatedAt.isAfter(oldTimestamp), isTrue);
    expect(hive.trackedDayBox.get(today.toDayKey())!.caloriesTracked, 2240);
  }

  test('adding on a past day replaces drift with the sum of its foods',
      () async {
    await intakes.addIntake(food('second', yesterday, amount: 50));
    expectYesterday(300, 45, 7.5, 15);
  });

  test('editing a past quantity recalculates all nutrients on that day',
      () async {
    await intakes.updateIntake('original', {'amount': 25.0});
    expectYesterday(50, 7.5, 1.25, 2.5);
  });

  test('deleting the last food clears drift on its actual day', () async {
    await intakes.deleteIntakeFromId('original');
    expectYesterday(0, 0, 0, 0);
  });

  test('bulk intake import recalculates existing totals', () async {
    await intakes.addAllIntakes([food('imported', yesterday, amount: 50)]);
    expectYesterday(300, 45, 7.5, 15);
  });

  test('importing a tracked day cannot replace intake totals with stale sums',
      () async {
    await days.saveAllTrackedDays([day(yesterday)]);
    expectYesterday(200, 30, 5, 10);
  });

  test('creating a tracked day after its intakes derives its totals', () async {
    await days.saveTrackedDay(day(yesterday));
    expectYesterday(200, 30, 5, 10);
  });
  test('startup repair is persistent and runs only once per user', () async {
    final migrations = await Hive.openBox<bool>('migrations');
    final totals =
        TrackedDayTotals(hive.intakeBox, hive.trackedDayBox, hive.macroGoalBox);
    await totals.migrate(migrations);
    expect(hive.trackedDayBox.get(yesterday.toDayKey())!.caloriesTracked, 200);
    expect(hive.trackedDayBox.get(today.toDayKey())!.caloriesTracked, 0);
    final firstRepair = hive.trackedDayBox.get(yesterday.toDayKey())!.updatedAt;
    await totals.migrate(migrations);
    expect(
        hive.trackedDayBox.get(yesterday.toDayKey())!.updatedAt, firstRepair);
    expect(migrations.get('tracked_day_totals_v1'), isTrue);
    await migrations.close();
  });

  test('servings are included in all four totals', () async {
    final serving = food('serving', yesterday)
      ..unit = 'serving'
      ..amount = 2;
    await intakes.addIntake(serving);
    expectYesterday(320, 48, 8, 16);
  });

  test('unchanged totals keep their modification timestamp', () async {
    await intakes.addIntake(food('second', yesterday, amount: 50));
    final updatedAt = hive.trackedDayBox.get(yesterday.toDayKey())!.updatedAt;
    await TrackedDayTotals(
            hive.intakeBox, hive.trackedDayBox, hive.macroGoalBox)
        .recalculate([yesterday]);
    expect(hive.trackedDayBox.get(yesterday.toDayKey())!.updatedAt, updatedAt);
  });

  test('copying then moving between days recalculates both dates', () async {
    final totals =
        TrackedDayTotals(hive.intakeBox, hive.trackedDayBox, hive.macroGoalBox);
    final migrations = await Hive.openBox<bool>('migrations');
    await totals.migrate(migrations);
    final destination = DateTime(2026, 11, 4);
    await intakes.addIntake(food('copy', destination));
    expect(
        hive.trackedDayBox.get(destination.toDayKey())!.caloriesTracked, 200);
    expect(hive.trackedDayBox.get(yesterday.toDayKey())!.caloriesTracked, 200);
    await intakes.deleteIntakeFromId('original');
    expect(hive.trackedDayBox.get(yesterday.toDayKey())!.caloriesTracked, 0);
    expect(
        hive.trackedDayBox.get(destination.toDayKey())!.caloriesTracked, 200);
  });

  test(
      'a day created by an imported intake uses the goals in force on that date',
      () async {
    final starts = DateTime(2026, 11, 5);
    await hive.macroGoalBox.put(
        'macro_goal', MacroGoalDbo('goal', starts, 200, 50, 100, 300, 70, 130));
    await intakes.addAllIntakes(
        [food('before', DateTime(2026, 11, 4)), food('after', starts)]);
    final before = hive.trackedDayBox.get(DateTime(2026, 11, 4).toDayKey())!;
    final after = hive.trackedDayBox.get(starts.toDayKey())!;
    expect(before.caloriesTracked, 200);
    expect(before.calorieGoal, 1650);
    expect(after.caloriesTracked, 200);
    expect(after.calorieGoal, 2350);
    expect(after.carbsGoal, 300);
    expect(after.fatGoal, 70);
    expect(after.proteinGoal, 130);
  });
  test('startup repairs French day keys before the UI locale is loaded',
      () async {
    final previousLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    addTearDown(() => Intl.defaultLocale = previousLocale);
    await hive.trackedDayBox.clear();
    await hive.trackedDayBox.put('02/11/2026', day(yesterday));
    await hive.trackedDayBox.put('03/11/2026', day(today));
    final migrations = await Hive.openBox<bool>('migrations');
    await TrackedDayTotals(
            hive.intakeBox, hive.trackedDayBox, hive.macroGoalBox)
        .migrate(migrations);
    expect(await days.getAllTrackedDays(), hasLength(2));
    expect((await days.getTrackedDay(yesterday))!.caloriesTracked, 200);
    expect((await days.getTrackedDay(today))!.caloriesTracked, 0);
    Intl.defaultLocale = 'fr_FR';
    expect((await days.getTrackedDay(yesterday))!.caloriesTracked, 200);
    expect((await days.getTrackedDay(yesterday))!.calorieGoal, 2020);
  });
  test('startup merges duplicate date keys and preserves the newest goals',
      () async {
    await hive.trackedDayBox.clear();
    final recent = day(yesterday)
      ..calorieGoal = 2200
      ..updatedAt = DateTime.utc(2026, 11, 2);
    final older = day(yesterday)..calorieGoal = 1800;
    await hive.trackedDayBox.put(yesterday.toDayKey(), recent);
    await hive.trackedDayBox.put('02/11/2026', older);
    final migrations = await Hive.openBox<bool>('migrations');
    await TrackedDayTotals(
            hive.intakeBox, hive.trackedDayBox, hive.macroGoalBox)
        .migrate(migrations);
    expect(await days.getAllTrackedDays(), hasLength(1));
    final repaired = (await days.getTrackedDay(yesterday))!;
    expect(repaired.caloriesTracked, 200);
    expect(repaired.calorieGoal, 2200);
  });
}
