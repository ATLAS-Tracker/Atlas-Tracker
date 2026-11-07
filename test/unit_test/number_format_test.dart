import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/number_format.dart';

void main() {
  test('French formatting is shared, including signed zero and quantities', () {
    expect(formatNumber(1991.6), '1\u202f992');
    expect(formatNumber(72.5, decimals: 1), '72,5');
    expect(formatNumber(-0.01, decimals: 1, signed: true), '0,0');
    expect(formatQuantity(150), '150');
    expect(formatQuantity(1.5), '1,5');
    expect(formatQuantity(1.25), '1,25');
    expect(formatQuantity(1000), '1\u202f000');
  });

  test('remaining calories use the displayed values and retain overruns', () {
    expect(remainingCalories(2140, 899.6), 1240);
    expect(remainingCalories(2000, 2600), -600);
  });

  test('goal tolerance agrees with the rounded displayed calories', () {
    expect(isWithinNutritionGoal(1799.6, 2000), isTrue);
    expect(isWithinNutritionGoal(2200.4, 2000), isTrue);
    expect(isWithinNutritionGoal(1050, 2000), isFalse);
    expect(isWithinNutritionGoal(0, 2000), isFalse);
    expect(isWithinNutritionGoal(100, 0), isFalse);
  });
  test('macro energy uses the same 4/4/9 calculation for integers and decimals',
      () {
    expect(macroCalories(carbs: 250, fat: 60, protein: 120), 2020);
    expect(macroCalories(carbs: 0.5, fat: 0.5, protein: 0.5), 8.5);
    expect(macroCalories(carbs: 0, fat: 0, protein: 0), 0);
  });

  test('capitalization handles empty text and accented names', () {
    expect(capitalizeFirst(''), '');
    expect(capitalizeFirst('énergie'), 'Énergie');
    expect(capitalizeFirst('7 jours'), '7 jours');
    expect(capitalizeFirst('🥗 salade'), '🥗 salade');
  });

  test('over-goal warning agrees with the displayed rounded values', () {
    expect(exceedsNutritionGoal(2200.4, 2000), isFalse);
    expect(exceedsNutritionGoal(2200.6, 2000), isTrue);
    expect(exceedsNutritionGoal(0, 0), isFalse);
  });
}
