import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'edit_meal_state.dart';

part 'edit_meal_event.dart';

class EditMealBloc extends Bloc<EditMealEvent, EditMealState> {
  final GetConfigUsecase _getConfigUsecase;

  EditMealBloc(this._getConfigUsecase) : super(EditMealInitial()) {
    on<InitializeEditMealEvent>((event, emit) async {
      emit(EditMealLoadingState());

      final config = await _getConfigUsecase.getConfig();
      emit(EditMealLoadedState(usesImperialUnits: config.usesImperialUnits));
    });
  }

  MealEntity createCustomFood(
      {required MealEntity original,
      required String name,
      required String brands,
      required bool perPortion,
      required String unit,
      required String portionName,
      required double kcal,
      required double carbs,
      required double fat,
      required double protein}) {
    // Nutriments use a /100 scale; the base unit here is one portion, never a synthetic gram.
    final factor = perPortion ? 100.0 : 1.0;
    return MealEntity(
      code: original.code,
      name: name.trim(),
      brands: brands.trim().isEmpty ? null : brands.trim(),
      url: original.url,
      thumbnailImageUrl: original.thumbnailImageUrl,
      mainImageUrl: original.mainImageUrl,
      mealQuantity: perPortion ? '1' : '100',
      mealUnit: perPortion ? 'serving' : unit,
      servingQuantity: perPortion ? 1 : null,
      servingUnit: perPortion ? 'serving' : null,
      servingSize: perPortion && portionName.trim().isNotEmpty
          ? portionName.trim()
          : null,
      nutriments: MealNutrimentsEntity(
        energyKcalPerQuantity: kcal * factor,
        carbohydratesPerQuantity: carbs * factor,
        fatPerQuantity: fat * factor,
        proteinsPerQuantity: protein * factor,
        sugarsPerQuantity: original.nutriments.sugarsPerQuantity,
        saturatedFatPerQuantity: original.nutriments.saturatedFatPerQuantity,
        fiberPerQuantity: original.nutriments.fiberPerQuantity,
        mealOrRecipe: original.nutriments.mealOrRecipe,
      ),
      source: original.source,
    );
  }

  MealEntity createNewMealEntity(
      MealEntity oldMealEntity,
      String nameText,
      String brandsText,
      String mealQuantityText,
      String servingQuantityText,
      String baseQuantity,
      String? unitText,
      String kcalText,
      String carbsText,
      String fatText,
      String proteinText) {
    final baseQuantityDouble = double.tryParse(baseQuantity);

    final double factorTo100g =
        baseQuantityDouble != null ? (100 / baseQuantityDouble) : 1;

    double? multiplyIfNotNull(double? nutrimentValue) {
      return nutrimentValue != null ? nutrimentValue * factorTo100g : null;
    }

    final newMealNutriments = MealNutrimentsEntity(
        energyKcalPerQuantity: multiplyIfNotNull(kcalText.toDoubleOrNull()),
        carbohydratesPerQuantity: multiplyIfNotNull(carbsText.toDoubleOrNull()),
        fatPerQuantity: multiplyIfNotNull(fatText.toDoubleOrNull()),
        proteinsPerQuantity: multiplyIfNotNull(proteinText.toDoubleOrNull()),
        sugarsPerQuantity:
            multiplyIfNotNull(oldMealEntity.nutriments.sugarsPerQuantity),
        saturatedFatPerQuantity:
            multiplyIfNotNull(oldMealEntity.nutriments.saturatedFatPerQuantity),
        fiberPerQuantity:
            multiplyIfNotNull(oldMealEntity.nutriments.fiberPerQuantity),
        mealOrRecipe: oldMealEntity.nutriments.mealOrRecipe);

    return MealEntity(
        code: oldMealEntity.code,
        name: nameText.toStringOrNull(),
        brands: brandsText.toStringOrNull(),
        url: oldMealEntity.url,
        thumbnailImageUrl: oldMealEntity.thumbnailImageUrl,
        mainImageUrl: oldMealEntity.mainImageUrl,
        mealQuantity: mealQuantityText.toStringOrNull(),
        mealUnit: unitText,
        servingQuantity: servingQuantityText.toDoubleOrNull(),
        servingUnit: servingQuantityText.toStringOrNull(),
        servingSize: oldMealEntity.servingSize,
        nutriments: newMealNutriments,
        source: oldMealEntity.source);
  }
}
