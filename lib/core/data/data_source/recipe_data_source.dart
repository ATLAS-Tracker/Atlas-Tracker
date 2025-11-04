import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class RecipesDataSource {
  final log = Logger('RecipesDataSource');
  final HiveDBProvider _hive;

  RecipesDataSource(this._hive);

  Future<void> _ensureReady() => _hive.ensureReady();

  /// Ajouter une recette complète
  Future<void> addRecipe(RecipesDBO recipe) async {
    await _ensureReady();
    log.fine('Adding new recipe to db');
    await _hive.recipeBox.put(
        recipe.recipe.code ?? recipe.recipe.name ?? "", recipe);
  }

  /// Ajouter plusieurs recettes
  Future<void> addAllRecipes(List<RecipesDBO> recipes) async {
    await _ensureReady();
    log.fine('Adding multiple recipes to db');
    final Map<String, RecipesDBO> entries = {
      for (var r in recipes) (r.recipe.code ?? r.recipe.name ?? ""): r
    };
    await _hive.recipeBox.putAll(entries);
  }

  /// Supprimer une recette à partir de son code ou nom
  Future<void> deleteRecipe(String key) async {
    await _ensureReady();
    log.fine('Deleting recipe with key $key');
    await _hive.recipeBox.delete(key);
  }

  /// Mettre à jour une recette (remplace tout l'objet)
  Future<void> updateRecipe(String key, RecipesDBO updatedRecipe) async {
    await _ensureReady();
    log.fine('Updating recipe with key $key');
    await _hive.recipeBox.put(key, updatedRecipe);
  }

  /// Obtenir une recette à partir de son code ou nom
  Future<RecipesDBO?> getRecipeByKey(String key) async {
    await _ensureReady();
    return _hive.recipeBox.get(key);
  }

  /// Obtenir toutes les recettes
  Future<List<RecipesDBO>> getAllRecipes() async {
    await _ensureReady();
    return _hive.recipeBox.values.toList();
  }

  /// Rechercher une recette par nom (contains)
  Future<List<RecipesDBO>> searchRecipes(String query) async {
    await _ensureReady();
    final lowerQuery = query.toLowerCase();
    return _hive.recipeBox.values
        .where((recipe) =>
            recipe.recipe.name?.toLowerCase().contains(lowerQuery) ?? false)
        .toList();
  }
}
