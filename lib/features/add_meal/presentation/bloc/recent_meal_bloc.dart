import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
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
        final searchString = (event.searchString).toLowerCase();
        final savedFoods = await _getRecipeUsecase.getSavedFoods();
        final seen = <String>{};
        final meals = [
          ...savedFoods,
          ...recentIntake.map((intake) => intake.meal.copyWith(
              mealQuantity: intake.amount.toString(), mealUnit: intake.unit)),
        ]
            .where((meal) =>
                seen.add(meal.code ?? meal.name ?? '') &&
                ((meal.name ?? '').toLowerCase().contains(searchString) ||
                    (meal.brands ?? '').toLowerCase().contains(searchString)))
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

  bool Function(IntakeEntity) matchesSearchString(String searchString) {
    return (intake) =>
        (intake.meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (intake.meal.brands?.toLowerCase().contains(searchString) ?? false);
  }
}
