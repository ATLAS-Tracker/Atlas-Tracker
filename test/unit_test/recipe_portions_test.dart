import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';

import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';

import '../fixture/recipe_entity_fixtures.dart';

void main() {
  test('portions survive the DBO/JSON round trip used by sync', () {
    final dbo = RecipesDBO.fromRecipeEntity(RecipeEntityFixtures.basicRecipe)
      ..portions = 10;
    final restored = RecipesDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())));
    expect(restored.portions, 10);
    expect(restored.toEntity().portions, 10);
  });

  test('recipes saved before portions existed read as one portion', () {
    final json = jsonDecode(jsonEncode(
        RecipesDBO.fromRecipeEntity(RecipeEntityFixtures.basicRecipe)
            .toJson())) as Map<String, dynamic>
      ..remove('portions');
    expect(RecipesDBO.fromJson(json).portions, 1);
  });

  test('a recipe is not a ×100 custom portion, so values show as stored', () {
    final meal = MealEntity(
      code: 'pancakes',
      name: 'Pancakes',
      url: null,
      mealQuantity: '1',
      mealUnit: 'serving',
      servingQuantity: 1,
      servingUnit: 'serving',
      servingSize: 'Portion',
      nutriments: MealNutrimentsEntity(
        energyKcalPerQuantity: 60,
        carbohydratesPerQuantity: 6.57,
        fatPerQuantity: 1.1,
        proteinsPerQuantity: 4.8,
        sugarsPerQuantity: null,
        saturatedFatPerQuantity: null,
        fiberPerQuantity: null,
        mealOrRecipe: MealOrRecipeEntity.recipe,
      ),
      source: MealSourceEntity.custom,
    );
    expect(meal.isPortionBased, isFalse);
  });
}
