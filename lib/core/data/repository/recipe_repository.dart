import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';

class RecipeRepository {
  final RecipesDataSource _dataSource;

  RecipeRepository(this._dataSource);

  /// Ajouter une recette
  Future<void> addRecipe(RecipeEntity recipeEntity) async {
    final dbo = RecipesDBO.fromRecipeEntity(recipeEntity);
    await _dataSource.addRecipe(dbo);
  }

  /// Supprimer une recette par son code ou nom
  Future<void> deleteRecipe(String key, {DateTime? deletedAt}) async {
    await _dataSource.deleteRecipe(key, deletedAt: deletedAt);
  }

  /// Mettre à jour une recette
  Future<void> updateRecipe(String key, RecipeEntity recipeEntity) async {
    final updatedDbo = RecipesDBO.fromRecipeEntity(recipeEntity);
    await _dataSource.updateRecipe(key, updatedDbo);
  }

  /// Récupérer une recette par sa clé (code ou nom)
  Future<RecipeEntity?> getRecipeByKey(String key) async {
    final dbo = await _dataSource.getRecipeByKey(key);
    return dbo?.toEntity();
  }

  /// Récupérer toutes les recettes
  Future<List<RecipeEntity>> getAllRecipes() async {
    final list = await _dataSource.getAllRecipes();
    return list
        .map((r) => r.toEntity())
        .where(
            (recipe) => recipe.meal.mealOrRecipe == MealOrRecipeEntity.recipe)
        .toList();
  }

  // The archive already stores the meal/recipe discriminator, so saved foods
  // share its persistence and backup format without creating journal entries.
  Future<void> saveFood(MealEntity food) =>
      addRecipe(RecipeEntity(meal: food, ingredients: const []));

  Future<List<MealEntity>> getSavedFoods() async =>
      (await _dataSource.getAllRecipes())
          .map((row) => row.toEntity().meal)
          .where((meal) => meal.mealOrRecipe == MealOrRecipeEntity.meal)
          .toList();

  /// Récupérer toutes les recettes au format DBO
  Future<List<RecipesDBO>> getAllRecipeDBOs() async {
    return await _dataSource.getAllRecipes();
  }

  /// Ajouter plusieurs recettes en DBO
  Future<void> addAllRecipeDBOs(List<RecipesDBO> recipes) async {
    await _dataSource.addAllRecipes(recipes);
  }

  /// Rechercher des recettes par texte
  Future<List<RecipeEntity>> searchRecipes(String query) async {
    final results = await _dataSource.searchRecipes(query);
    return results.map((r) => r.toEntity()).toList();
  }
}
