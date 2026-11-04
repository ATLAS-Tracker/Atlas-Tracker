import 'dart:io';
import 'dart:convert';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';

import '../fixture/meal_entity_fixtures.dart';
import '../fixture/intake_for_recipe_fixtures.dart';

void main() {
  group('IntakeRepository test', () {
    late Directory directory;
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.registerAdapter(IntakeDBOAdapter());
      Hive.registerAdapter(TrackedDayDBOAdapter());
      Hive.registerAdapter(IntakeTypeDBOAdapter());
      Hive.registerAdapter(MealDBOAdapter());
      Hive.registerAdapter(MealSourceDBOAdapter());
      Hive.registerAdapter(MealNutrimentsDBOAdapter());
      Hive.registerAdapter(MealOrRecipeDBOAdapter());
    });

    setUp(() async {
      directory =
          await Directory.systemTemp.createTemp('atlas_intake_repository_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('moving an intake preserves its ID and repairs both days', () async {
      final hive = HiveDBProvider();
      hive.intakeBox = await Hive.openBox<IntakeDBO>('intakes');
      hive.macroGoalBox = await Hive.openBox<MacroGoalDbo>('goals');
      hive.trackedDayBox = await Hive.openBox<TrackedDayDBO>('days');
      final repo = IntakeRepository(IntakeDataSource(hive));
      final source = DateTime(2026, 11, 1);
      final target = DateTime(2026, 11, 2);
      final intake = IntakeEntity(
          id: 'move',
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.breakfast,
          meal: IntakeForRecipeFixtures.chicken.meal!,
          dateTime: source);
      await repo.addIntake(intake);
      await repo.updateIntake(
          'move', {'dateTime': target, 'type': IntakeTypeEntity.dinner});
      expect(hive.intakeBox.length, 1);
      final moved = (await repo.getIntakeById('move'))!;
      expect(moved.dateTime, target);
      expect(moved.type, IntakeTypeEntity.dinner);
      expect(hive.trackedDayBox.get('2026-11-01')!.caloriesTracked, 0);
      expect(hive.trackedDayBox.get('2026-11-02')!.caloriesTracked,
          intake.totalKcal);
    });

    test('returns last added first', () async {
      final box = await Hive.openBox<IntakeDBO>('intake_test');

      final hive = HiveDBProvider();
      hive.intakeBox = box;
      hive.macroGoalBox = await Hive.openBox<MacroGoalDbo>('goals');
      hive.trackedDayBox = await Hive.openBox<TrackedDayDBO>('days');
      final repo = IntakeRepository(IntakeDataSource(hive));

      await repo.addIntake(
        IntakeEntity(
          id: "1",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealOne,
          dateTime: DateTime.utc(2024, 1, 1, 0, 0, 0),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await repo.addIntake(
        IntakeEntity(
          id: "2",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealTwo,
          dateTime: DateTime.utc(2024, 1, 2, 0, 0, 0),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await repo.addIntake(
        IntakeEntity(
          id: "3",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealThree,
          dateTime: DateTime.utc(2024, 1, 3, 0, 0, 0),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final recents = (await repo.getRecentIntake()).map((e) => e.id).toList();
      expect(recents, List.from(["3", "2", "1"]));
    });

    test('deletion survives restart, rejects stale import and allows undo',
        () async {
      final hive = HiveDBProvider(userId: 'owner');
      hive.intakeBox = await Hive.openBox<IntakeDBO>('intakes');
      hive.macroGoalBox = await Hive.openBox<MacroGoalDbo>('goals');
      hive.trackedDayBox = await Hive.openBox<TrackedDayDBO>('days');
      hive.syncMetadataBox = await Hive.openBox<String>('sync');
      final repo = IntakeRepository(IntakeDataSource(hive));
      final intake = IntakeEntity(
          id: 'deleted',
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.lunch,
          meal: IntakeForRecipeFixtures.chicken.meal!,
          dateTime: DateTime(2026, 11, 1));
      await repo.addIntake(intake);
      final stale = IntakeDBO.fromJson(
          jsonDecode(jsonEncode(hive.intakeBox.values.single.toJson()))
              as Map<String, dynamic>);
      await repo.deleteIntake(intake);
      await hive.syncMetadataBox!.close();
      hive.syncMetadataBox = await Hive.openBox<String>('sync');
      final deleted = SyncMetadata(hive.syncMetadataBox)
          .deletedAt('user_intakes', intake.id);
      expect(deleted, isNotNull);
      await repo.addAllIntakeDBOs([stale]);
      expect(hive.intakeBox.values, isEmpty);
      await repo.addIntake(intake);
      expect(hive.intakeBox.values.single.updatedAt.isAfter(deleted!), isTrue);
      expect(hive.intakeBox.length, 1);
      expect(hive.trackedDayBox.get('2026-11-01')!.caloriesTracked, 165);
    });
  });
}
