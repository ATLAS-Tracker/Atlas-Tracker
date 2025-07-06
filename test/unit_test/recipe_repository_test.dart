import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/data/dbo/intake_recipe_dbo.dart';

import '../fixture/recipe_entity_fixtures.dart';


void main() {
  group('Recipe add/replace logic', () {
    late Box<RecipesDBO> box;
    late Directory tempDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      Hive.registerAdapter(RecipesDBOAdapter());
      Hive.registerAdapter(MealDBOAdapter());
      Hive.registerAdapter(MealNutrimentsDBOAdapter());
      Hive.registerAdapter(MealSourceDBOAdapter());
      Hive.registerAdapter(IntakeForRecipeDBOAdapter());
      Hive.registerAdapter(MealOrRecipeDBOAdapter());

      box = await Hive.openBox<RecipesDBO>('recipes_test');
      final hive = HiveDBProvider();
      hive.recipeBox = box;
      final dataSource = RecipesDataSource(hive);
      final repo = RecipeRepository(dataSource);
      final addRecipeUsecase = AddRecipeUsecase(repo);
      final deleteRecipeUsecase = DeleteRecipeUsecase(repo);

      locator.registerSingleton<AddRecipeUsecase>(addRecipeUsecase);
      locator.registerSingleton<DeleteRecipeUsecase>(deleteRecipeUsecase);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteFromDisk();
      locator.reset();
      await tempDir.delete(recursive: true);
    });

    test('remplace une recette existante par une nouvelle', () async {
      const recipeId = 'recipe_to_replace';

      // Add initial recipe
      final originalRecipe = RecipeEntityFixtures.basicRecipe.copyWith(
        meal: RecipeEntityFixtures.basicRecipe.meal.copyWith(code: recipeId),
      );
      await locator<AddRecipeUsecase>().addRecipe(originalRecipe);

      final initialRecipes = box.values.toList();
      expect(initialRecipes.length, 1);
      final initial = initialRecipes.first;
      expect(initial.recipe.code, recipeId);
      expect(initial.recipe.name, 'Mocked Meal');
      expect(initial.recipe.mealQuantity, '1');
      expect(initial.recipe.servingSize, '100g');
      expect(initial.ingredients.length, 2);
      expect(initial.ingredients[0].name, 'Rice');
      expect(initial.ingredients[1].amount, 100);

      // Simulate the "edit" logic: delete the old one
      await locator<DeleteRecipeUsecase>().deleteRecipe(recipeId);

      // Add a new recipe (new code)
      final newRecipe = RecipeEntityFixtures.basicRecipe.copyWith(
        meal: RecipeEntityFixtures.basicRecipe.meal
            .copyWith(code: 'new_recipe_id'),
      );
      await locator<AddRecipeUsecase>().addRecipe(newRecipe);

      final allRecipes = box.values.toList();
      expect(allRecipes.length, 1);
      expect(allRecipes.first.recipe.code, 'new_recipe_id');
    });
  });

  group('Recipe deletion removes image', () {
    late Box<RecipesDBO> box;
    late Directory tempDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('hive_test_del_');
      Hive.init(tempDir.path);

      box = await Hive.openBox<RecipesDBO>('recipes_test');
      final hive = HiveDBProvider();
      hive.recipeBox = box;
      final dataSource = RecipesDataSource(hive);
      final repo = RecipeRepository(dataSource);
      locator.registerSingleton<AddRecipeUsecase>(AddRecipeUsecase(repo));
      locator.registerSingleton<DeleteRecipeUsecase>(DeleteRecipeUsecase(repo));
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteFromDisk();
      locator.reset();
      await tempDir.delete(recursive: true);
    });

    test('delete removes recipe and local image', () async {
      final imagePath = '${tempDir.path}/img.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsString('test');

      final recipe = RecipeEntityFixtures.basicRecipe.copyWith(
        meal: RecipeEntityFixtures.basicRecipe.meal.copyWith(
          code: 'to_delete',
          url: imagePath,
          thumbnailImageUrl: imagePath,
          mainImageUrl: imagePath,
        ),
      );
      await locator<AddRecipeUsecase>().addRecipe(recipe);
      expect(box.values.length, 1);
      expect(await imageFile.exists(), true);

      await locator<DeleteRecipeUsecase>().deleteRecipe('to_delete');
      expect(box.values.isEmpty, true);
      expect(await imageFile.exists(), false);
    });
  });
}
