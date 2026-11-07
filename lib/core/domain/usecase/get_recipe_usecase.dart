import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class GetRecipeUsecase {
  final RecipeRepository _recipeRepository;

  GetRecipeUsecase(this._recipeRepository);

  Future<RecipeEntity?> getRecipeById(String id) async {
    return _recipeRepository.getRecipeByKey(id);
  }

  Future<List<RecipeEntity>> getAllRecipes() async {
    return _recipeRepository.getAllRecipes();
  }

  Future<List<MealEntity>> getSavedFoods() => _recipeRepository.getSavedFoods();
}
