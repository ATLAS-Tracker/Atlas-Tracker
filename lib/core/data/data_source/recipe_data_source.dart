import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';

class RecipesDataSource {
  final log = Logger('RecipesDataSource');
  final HiveDBProvider _hive;

  RecipesDataSource(this._hive);

  /// Ajouter une recette complète
  Future<void> addRecipe(RecipesDBO recipe) async {
    log.fine('Adding new recipe to db');
    final key = recipe.recipe.code ?? recipe.recipe.name ?? '';
    recipe.updatedAt = SyncMetadata(_hive.syncMetadataBox).nextLocalVersion(
        'user_recipes', key, _hive.recipeBox.get(key)?.updatedAt);
    await _hive.recipeBox
        .put(recipe.recipe.code ?? recipe.recipe.name ?? "", recipe);
  }

  /// Ajouter plusieurs recettes
  Future<void> addAllRecipes(List<RecipesDBO> recipes) async {
    log.fine('Adding multiple recipes to db');
    final entries = <String, RecipesDBO>{};
    final metadata = SyncMetadata(_hive.syncMetadataBox);
    for (final recipe in recipes) {
      final key = recipe.recipe.code ?? recipe.recipe.name ?? '';
      final current = entries[key] ?? _hive.recipeBox.get(key);
      final deleted = metadata.deletedAt('user_recipes', key);
      if ((current == null || recipe.updatedAt.isAfter(current.updatedAt)) &&
          (deleted == null || recipe.updatedAt.isAfter(deleted))) {
        entries[key] = recipe;
      }
    }
    await _hive.recipeBox.putAll(entries);
  }

  /// Supprimer une recette à partir de son code ou nom
  Future<void> deleteRecipe(String key, {DateTime? deletedAt}) async {
    log.fine('Deleting recipe with key $key');
    await SyncMetadata(_hive.syncMetadataBox).markDeleted('user_recipes', key,
        previous: _hive.recipeBox.get(key)?.updatedAt, version: deletedAt);
    await _hive.recipeBox.delete(key);
  }

  /// Mettre à jour une recette (remplace tout l'objet)
  Future<void> updateRecipe(String key, RecipesDBO updatedRecipe) async {
    log.fine('Updating recipe with key $key');
    updatedRecipe.updatedAt = SyncMetadata(_hive.syncMetadataBox)
        .nextLocalVersion(
            'user_recipes', key, _hive.recipeBox.get(key)?.updatedAt);
    await _hive.recipeBox.put(key, updatedRecipe);
  }

  /// Obtenir une recette à partir de son code ou nom
  Future<RecipesDBO?> getRecipeByKey(String key) async {
    return _hive.recipeBox.get(key);
  }

  /// Obtenir toutes les recettes
  Future<List<RecipesDBO>> getAllRecipes() async {
    return _hive.recipeBox.values.toList();
  }

  /// Rechercher une recette par nom (contains)
  Future<List<RecipesDBO>> searchRecipes(String query) async {
    final lowerQuery = query.toLowerCase();
    return _hive.recipeBox.values
        .where((recipe) =>
            recipe.recipe.name?.toLowerCase().contains(lowerQuery) ?? false)
        .toList();
  }
}
