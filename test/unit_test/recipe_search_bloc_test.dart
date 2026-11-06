import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';

class MockGetRecipe extends Mock implements GetRecipeUsecase {}

class MockDeleteRecipe extends Mock implements DeleteRecipeUsecase {}

void main() {
  for (final query in ['boeuf', 'bœuf', ' BŒUF ']) {
    test('recipe search folds both names and brands: $query', () async {
      final recipes = MockGetRecipe();
      final foods = [
        MealEntity.empty().copyWith(code: 'a', name: 'Boeuf'),
        MealEntity.empty().copyWith(code: 'b', name: 'Bœuf'),
        MealEntity.empty().copyWith(code: 'c', name: 'Poulet', brands: 'Bœuf'),
        MealEntity.empty().copyWith(code: 'd', name: 'Riz'),
      ];
      when(() => recipes.getAllRecipes()).thenAnswer((_) async => foods
          .map((meal) => RecipeEntity(meal: meal, ingredients: []))
          .toList());
      final bloc = RecipeSearchBloc(recipes, MockDeleteRecipe());
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((s) => s is RecipeLoadedState);
      bloc.add(LoadRecipeSearchEvent(searchString: query));
      expect((await loaded as RecipeLoadedState).recipes, foods.take(3));
    });
  }
}
