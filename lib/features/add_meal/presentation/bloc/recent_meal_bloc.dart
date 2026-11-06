import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/search_match.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recent_meal_event.dart';

part 'recent_meal_state.dart';

class RecentMealBloc extends Bloc<RecentMealEvent, RecentMealState> {
  final log = Logger('RecentMealBloc');

  final GetIntakeUsecase _getIntakeUsecase;
  final GetRecipeUsecase _getRecipeUsecase;

  RecentMealBloc(this._getIntakeUsecase, this._getRecipeUsecase)
      : super(RecentMealInitial()) {
    on<LoadRecentMealEvent>((event, emit) async {
      emit(RecentMealLoadingState());
      try {
        final recentIntake = await _getIntakeUsecase.getRecentIntake();
        final searchString = foldText(event.searchString);
        final savedFoods = await _getRecipeUsecase.getSavedFoods();
        final seen = <String>{};
        final meals = [
          ...savedFoods,
          ...recentIntake.map((intake) => intake.meal.copyWith(
              mealQuantity: intake.amount.toString(), mealUnit: intake.unit)),
        ]
            .where((meal) =>
                seen.add(meal.code ?? meal.name ?? '') &&
                (foldText(meal.name ?? '').contains(searchString) ||
                    foldText(meal.brands ?? '').contains(searchString)))
            .toList();
        emit(RecentMealLoadedState(recentMeals: meals, lastIntakes: {
          for (final intake in recentIntake)
            intake.meal.code ?? intake.meal.name ?? '': intake,
        }));
      } catch (error) {
        log.severe(error);
        emit(RecentMealFailedState());
      }
    });
  }
}
