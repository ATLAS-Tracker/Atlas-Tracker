import 'package:opennutritracker/core/utils/search_match.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recipe_search_event.dart';

part 'recipe_search_state.dart';

class RecipeSearchBloc extends Bloc<RecipeSearchEvent, RecipeSearchState> {
  final log = Logger('RecipeSearchBloc');

  final GetRecipeUsecase _getRecipeUsecase;

  RecipeSearchBloc(this._getRecipeUsecase) : super(RecipeInitial()) {
    on<LoadRecipeSearchEvent>((event, emit) async {
      emit(RecipeLoadingState());
      try {
        final recipeIntake = await _getRecipeUsecase.getAllRecipes();
        final searchString = foldText(event.searchString);

        if (searchString.isEmpty) {
          emit(RecipeLoadedState(
            recipes: recipeIntake.map((intake) => intake.meal).toList(),
          ));
        } else {
          emit(RecipeLoadedState(
            recipes: recipeIntake
                .where((intake) => matchesSearchString(searchString)(intake))
                .map((intake) => intake.meal)
                .toList(),
          ));
        }
      } catch (error) {
        log.severe(error);
        emit(RecipeFailedState());
      }
    });
  }

  bool Function(RecipeEntity) matchesSearchString(String searchString) {
    return (intake) =>
        foldText(intake.meal.name ?? '').contains(foldText(searchString)) ||
        foldText(intake.meal.brands ?? '').contains(foldText(searchString));
  }
}
