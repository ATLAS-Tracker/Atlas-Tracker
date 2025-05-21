import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';

part 'recipe_search_event.dart';

part 'recipe_search_state.dart';

class RecipeSearchBloc extends Bloc<RecipeSearchEvent, RecipeSearchState> {
  final log = Logger('RecipeSearchBloc');

  final GetRecipeUsecase _getRecipeUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final DeleteRecipeUsecase _deleteRecipeUsecase;

  RecipeSearchBloc(
      this._getRecipeUsecase, this._getConfigUsecase, this._deleteRecipeUsecase)
      : super(RecipeInitial()) {
    on<LoadRecipeSearchEvent>((event, emit) async {
      emit(RecipeLoadingState());
      try {
        final config = await _getConfigUsecase.getConfig();
        final recipeIntake = await _getRecipeUsecase.getAllRecipes();
        final searchString = (event.searchString).toLowerCase();

        if (searchString.isEmpty) {
          emit(RecipeLoadedState(
            recipes: recipeIntake.map((intake) => intake.meal).toList(),
            usesImperialUnits: config.usesImperialUnits,
          ));
        } else {
          emit(RecipeLoadedState(
            recipes: recipeIntake
                .where((intake) => matchesSearchString(searchString)(intake))
                .map((intake) => intake.meal)
                .toList(),
            usesImperialUnits: config.usesImperialUnits,
          ));
        }
      } catch (error) {
        log.severe(error);
        emit(RecipeFailedState());
      }
    });
    on<DeleteRecipeEvent>((event, emit) async {
      try {
        final recipeId = (event.recipeId).toLowerCase();
        _deleteRecipeUsecase.deleteRecipe(recipeId);
        final recipeIntake = await _getRecipeUsecase.getAllRecipes();
        final config = await _getConfigUsecase.getConfig();
        emit(RecipeLoadedState(
          recipes: recipeIntake.map((intake) => intake.meal).toList(),
          usesImperialUnits: config.usesImperialUnits,
        ));
      } catch (error) {
        log.severe(error);
        emit(RecipeFailedState());
      }
    });
  }

  bool Function(RecipeEntity) matchesSearchString(String searchString) {
    return (intake) =>
        (intake.meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (intake.meal.brands?.toLowerCase().contains(searchString) ?? false);
  }
}
