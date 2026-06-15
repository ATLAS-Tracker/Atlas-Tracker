import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/sync/journal_remote_sync_service.dart';

void main() {
  group('JournalRemoteSyncService diff helpers', () {
    test('pulls remote intakes missing locally or newer than local', () {
      final local = [
        intake('same', updatedAt: DateTime.utc(2026, 6, 8, 8)),
      ];
      final remote = [
        intake('same', updatedAt: DateTime.utc(2026, 6, 8, 9)),
        intake('remote-only', updatedAt: DateTime.utc(2026, 6, 7, 9)),
      ];

      final toSave = JournalRemoteSyncService.remoteIntakesToSave(
        local: local,
        remote: remote,
      );

      expect(toSave.map((i) => i.id), containsAll(['same', 'remote-only']));
    });

    test('pushes local intakes missing remotely or newer than remote', () {
      final local = [
        intake('same', updatedAt: DateTime.utc(2026, 6, 8, 10)),
        intake('local-only', updatedAt: DateTime.utc(2026, 6, 9, 8)),
      ];
      final remote = [
        intake('same', updatedAt: DateTime.utc(2026, 6, 8, 9)),
      ];

      final toUpload = JournalRemoteSyncService.localIntakesToUpload(
        local: local,
        remote: remote,
      );

      expect(toUpload.map((i) => i.id), containsAll(['same', 'local-only']));
    });

    test('pulls only remote recipes that are not present locally', () {
      final local = [recipe('omelette')];
      final remote = [recipe('omelette'), recipe('pancakes')];

      final toSave = JournalRemoteSyncService.remoteRecipesToSave(
        local: local,
        remote: remote,
      );

      expect(toSave.map(JournalRemoteSyncService.recipeKey), ['pancakes']);
    });

    test('pushes only local recipes that are not present remotely', () {
      final local = [recipe('omelette'), recipe('salad')];
      final remote = [recipe('omelette')];

      final toUpload = JournalRemoteSyncService.localRecipesToUpload(
        local: local,
        remote: remote,
      );

      expect(toUpload.map(JournalRemoteSyncService.recipeKey), ['salad']);
    });
  });
}

IntakeDBO intake(String id, {required DateTime updatedAt}) {
  return IntakeDBO(
    id: id,
    unit: 'g',
    amount: 100,
    type: IntakeTypeDBO.breakfast,
    meal: meal(id),
    dateTime: DateTime.utc(2026, 6, 8, 8),
    updatedAt: updatedAt,
  );
}

RecipesDBO recipe(String key) {
  return RecipesDBO(
    recipe: meal(key),
    ingredients: const [],
  );
}

MealDBO meal(String key) {
  return MealDBO(
    code: key,
    name: key,
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: null,
    mealUnit: null,
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsDBO(
      energyKcalPerQuantity: 100,
      carbohydratesPerQuantity: 10,
      fatPerQuantity: 5,
      proteinsPerQuantity: 8,
      sugarsPerQuantity: null,
      saturatedFatPerQuantity: null,
      fiberPerQuantity: null,
      mealOrRecipe: MealOrRecipeDBO.meal,
    ),
    source: MealSourceDBO.custom,
  );
}
