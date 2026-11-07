import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

MealEntity createCustomFood(
    {required MealEntity original,
    required String name,
    required String brands,
    required bool perPortion,
    required String unit,
    required String portionName,
    String? photoPath,
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
    thumbnailImageUrl: photoPath ?? original.thumbnailImageUrl,
    mainImageUrl: photoPath ?? original.mainImageUrl,
    mealQuantity: perPortion ? '1' : '100',
    mealUnit: perPortion ? 'serving' : unit,
    servingQuantity: perPortion ? 1 : null,
    servingUnit: perPortion ? 'serving' : null,
    servingSize:
        perPortion && portionName.trim().isNotEmpty ? portionName.trim() : null,
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
    source: MealSourceEntity.custom,
  );
}
