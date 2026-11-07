import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

void main() {
  MealEntity product(String? package, dynamic quantity, String? portion) =>
      MealEntity.fromOFFProduct(OFFProductDTO.fromJson({
        'quantity': package,
        'serving_quantity': quantity,
        'serving_size': portion,
        'nutriments': <String, dynamic>{},
      }));

  test('ice cream serving keeps its grams when the package uses milliliters',
      () {
    final meal = product('440 ml (4 x 110 ml) (328 g)', 82, '82 g');
    expect(meal.servingQuantity, 82);
    expect(meal.servingUnit, 'g');
  });

  test('mixed ice cream portion uses its weight, not its numeric volume', () {
    final meal = product('328 g', 110, '82 g / 110 ml');
    expect(meal.servingQuantity, 82);
    expect(meal.servingUnit, 'g');
  });

  test('ice cream tub volume does not override the serving weight', () {
    final meal = product('1 l', 50, '50g');
    expect(meal.servingQuantity, 50);
    expect(meal.servingUnit, 'g');
  });

  test('drink portion retains its milliliters', () {
    final meal = product('6 x 1 l', 200, '200 ml');
    expect(meal.servingQuantity, 200);
    expect(meal.servingUnit, 'ml');
  });

  test('portion text supplies a missing numeric serving and package unit', () {
    final meal = product(null, null, '1 biscuit (18,8 g)');
    expect(meal.servingQuantity, 18.8);
    expect(meal.servingUnit, 'g');
    expect(meal.hasServingValues, isTrue);
  });

  test('scaled portion units are converted to the base unit', () {
    final meal = product('1 l', 20, '20 cl');
    expect(meal.servingQuantity, 200);
    expect(meal.servingUnit, 'ml');
  });

  test('numeric serving still works without a physical portion description',
      () {
    final meal = product('300 g', '20', '1 biscuit');
    expect(meal.servingQuantity, 20);
    expect(meal.servingUnit, 'g');
    expect(product('300 g', null, null).hasServingValues, isFalse);
  });
}
