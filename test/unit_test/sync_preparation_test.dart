import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/sync/sync_preparation.dart';
import '../fixture/intake_for_recipe_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 10);
  final day = DateTime(2026, 11, 3);
  IntakeDBO intake(String id, double amount, int hour) =>
      IntakeDBO.fromIntakeEntity(IntakeEntity(
          id: id,
          unit: 'g',
          amount: amount,
          type: IntakeTypeEntity.lunch,
          meal: IntakeForRecipeFixtures.chicken.meal!,
          dateTime: day,
          updatedAt: DateTime.utc(2026, 11, 4, hour)));
  PreparedSyncSnapshot prepare(
          {String? owner = 'owner',
          List<IntakeDBO> intakes = const [],
          List<TrackedDayDBO> days = const [],
          List<UserWeightDbo> weights = const [],
          List<RecipesDBO> recipes = const [],
          List<Map<String, dynamic>> deletions = const []}) =>
      SyncPreparation.prepare(
          userId: 'owner',
          ownerId: owner,
          now: now,
          intakes: intakes,
          days: days,
          weights: weights,
          recipes: recipes,
          deletions: deletions);

  test('no row from another user scope can be sent', () {
    final snapshot =
        prepare(owner: 'other', intakes: [intake('foreign', 100, 8)]);
    expect(snapshot.tables, isEmpty);
    expect(snapshot.userId, isNull);
  });
  test('totals are recomputed after newest-version deduplication', () {
    final snapshot = prepare(intakes: [
      intake('same', 50, 7),
      intake('same', 100, 8)
    ], days: [
      TrackedDayDBO(
          day: day,
          calorieGoal: 2000,
          caloriesTracked: 2240,
          updatedAt: DateTime.utc(2026, 11, 4, 8))
    ]);
    expect(snapshot.rows('user_intakes'), hasLength(1));
    expect(snapshot.rows('tracked_days').single['caloriesTracked'], 165);
    expect(snapshot.rows('tracked_days').single['proteinTracked'], 31);
    expect(
        snapshot.tables.values
            .expand((rows) => rows)
            .every((row) => row['user_id'] == 'owner'),
        isTrue);
  });
  test('invalid values and implausible weights are never serialized', () {
    final snapshot = prepare(intakes: [
      intake('invalid', double.nan, 8)
    ], weights: [
      UserWeightDbo('negative', -1, day, now),
      UserWeightDbo(
          'infinite', double.infinity, day.add(const Duration(days: 1)), now),
      UserWeightDbo('too-heavy', 401, day.add(const Duration(days: 2)), now),
    ]);
    expect(snapshot.rows('user_intakes'), isEmpty);
    expect(snapshot.rows('user_weight'), isEmpty);
    expect(snapshot.rejected, hasLength(4));
  });
  test('timestamps are retained and recipes are not retimestamped on upload',
      () {
    final version = DateTime.utc(2026, 11, 4, 8);
    final recipe = RecipesDBO(
        recipe: MealDBO.fromMealEntity(IntakeForRecipeFixtures.chicken.meal!),
        ingredients: [],
        updatedAt: version);
    expect(
        prepare(recipes: [recipe]).rows('user_recipes').single['modified_at'],
        version.toIso8601String());
    final future = intake('future', 100, 12);
    expect(prepare(intakes: [future]).rows('user_intakes'), isEmpty);
  });
  test('deletion wins over stale data, and a later undo wins over deletion',
      () {
    final tombstone = {
      'table': 'user_intakes',
      'record_id': 'food',
      'modified_at': DateTime.utc(2026, 11, 4, 8).toIso8601String()
    };
    final deleted =
        prepare(intakes: [intake('food', 100, 7)], deletions: [tombstone]);
    expect(deleted.rows('user_intakes').single['deleted_at'],
        tombstone['modified_at']);
    final restored =
        prepare(intakes: [intake('food', 100, 9)], deletions: [tombstone]);
    expect(restored.rows('user_intakes').single['deleted_at'], isNull);
    expect(restored.rows('tracked_days').single['caloriesTracked'], 165);
  });
  test('prepared JSON is detached from mutable Hive objects', () {
    final record = intake('food', 100, 8);
    final snapshot = prepare(intakes: [record]);
    record.amount = 999;
    final payload = snapshot.rows('user_intakes').single['payload'] as Map;
    expect(payload['amount'], 100);
    expect(payload['meal'], isA<Map<String, dynamic>>());
  });
}
