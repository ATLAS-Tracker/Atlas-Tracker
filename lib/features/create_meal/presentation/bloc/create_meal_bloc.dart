import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_for_recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

part 'create_meal_event.dart';
part 'create_meal_state.dart';

class CreateMealBloc extends Bloc<CreateMealEvent, CreateMealState> {
  final GetRecipeUsecase _recipeUsecase;
  List<IntakeForRecipeEntity> _intakeList = [];

  CreateMealBloc(this._recipeUsecase) : super(const CreateMealState()) {
    on<InitializeCreateMealEvent>((event, emit) async {
      emit(state.copyWith(isOnCreateMealScreen: true));
    });

    on<ExitCreateMealScreenEvent>((event, emit) async {
      clearIntakeList();
      emit(state.copyWith(isOnCreateMealScreen: false));
    });

    on<SetIntakeListFromRecipeEvent>((event, emit) {
      _intakeList = List.from(event.ingredients);
      _emitUpdatedState();
    });
  }

  List<IntakeForRecipeEntity> getListOfIntakeForRecipeEntity() => _intakeList;

  void setListOfIntakeForRecipeEntity(List<IntakeForRecipeEntity> list) {
    _intakeList = list;
  }

  void clearIntakeList() {
    _intakeList.clear();
    _emitUpdatedState();
  }

  Future<void> addIntake(
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async {
    final quantity = double.tryParse(amountText.replaceAll(',', '.'));
    if (quantity == null) return;

    if (meal.mealOrRecipe == MealOrRecipeEntity.recipe) {
      final recipe = await _recipeUsecase.getRecipeById(meal.code!);
      if (recipe == null) return;

      for (final ingredient in recipe.ingredients) {
        final intake = IntakeForRecipeEntity(
          code: ingredient.code ?? IdGenerator.getUniqueID(),
          unit: ingredient.unit ?? "g",
          amount: ingredient.amount ?? 0,
          meal: ingredient.meal,
        );
        _intakeList.add(intake);
      }
    } else {
      final intakeEntity = IntakeForRecipeEntity(
        code: IdGenerator.getUniqueID(),
        unit: unit,
        amount: quantity,
        meal: meal,
      );
      _intakeList.add(intakeEntity);
    }

    _emitUpdatedState();
  }

  void removeIntake(String intakeId) {
    _intakeList.removeWhere((intake) => intake.code == intakeId);
    _emitUpdatedState();
  }

  void updateIntakeAmount(String intakeId, double newAmount) {
    final index = _intakeList.indexWhere((intake) => intake.code == intakeId);
    if (index != -1) {
      _intakeList[index] = _intakeList[index].copyWith(amount: newAmount);
      _emitUpdatedState();
    }
  }

  void _emitUpdatedState() {
    final totals = computeMacros();
    // ignore: invalid_use_of_visible_for_testing_member
    emit(state.copyWith(
      intakeList: List.from(_intakeList),
      totalProteins: totals['totalProteins']!,
      totalCarbs: totals['totalCarbs']!,
      totalFats: totals['totalFats']!,
    ));
  }

  Map<String, double> computeMacros() {
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    double totalKcal = 0;

    for (final intake in _intakeList) {
      final meal = intake.meal;
      final amount = intake.amount ?? 0;

      if (meal != null) {
        final nutriments = meal.nutriments;
        totalProteins += (nutriments.proteinsPerUnit ?? 0) * amount;
        totalCarbs += (nutriments.carbohydratesPerUnit ?? 0) * amount;
        totalFats += (nutriments.fatPerUnit ?? 0) * amount;
        totalKcal += (nutriments.energyPerUnit ?? 0) * amount;
      }
    }

    return {
      'totalProteins': totalProteins,
      'totalCarbs': totalCarbs,
      'totalFats': totalFats,
      'totalKcal': totalKcal,
    };
  }
}
