import 'package:opennutritracker/core/data/repository/recipe_repository.dart';

class DeleteRecipeUsecase {
  final RecipeRepository _recipeRepository;

  DeleteRecipeUsecase(this._recipeRepository);

  Future<void> deleteRecipe(String recipeId) async {
    // Historic intakes and undo may still reference the recipe's photos.
    await _recipeRepository.deleteRecipe(recipeId);
  }
}
