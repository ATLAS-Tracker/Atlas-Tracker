import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

class MockGetConfigUsecase extends Mock implements GetConfigUsecase {}

void main() {
  late EditMealBloc bloc;
  setUp(() => bloc = EditMealBloc(MockGetConfigUsecase()));
  tearDown(() => bloc.close());

  MealEntity create(bool portion, String unit) => bloc.createCustomFood(
      original: MealEntity.empty(),
      name: 'Nuggets',
      brands: '',
      perPortion: portion,
      unit: unit,
      portionName: '6 nuggets',
      kcal: 250,
      carbs: 20,
      fat: 12,
      protein: 15);

  for (final count in [0.5, 1.0, 2.0]) {
    test(
        '$count portions calculate correctly after persistence and recent reuse',
        () {
      final food = create(true, 'g');
      final restored = MealEntity.fromMealDBO(MealDBO.fromJson(
          jsonDecode(jsonEncode(MealDBO.fromMealEntity(food).toJson()))
              as Map<String, dynamic>));
      final recent = restored.copyWith(
          mealQuantity: count.toString(), mealUnit: 'serving');
      expect(recent.isPortionBased, isTrue);
      expect(recent.servingSize, '6 nuggets');
      expect(recent.isSolid, isFalse);
      final intake = IntakeEntity(
          id: 'test',
          unit: 'serving',
          amount: count,
          type: IntakeTypeEntity.lunch,
          meal: recent,
          dateTime: DateTime(2026, 10, 24));
      expect(intake.totalKcal, 250 * count);
      expect(intake.totalCarbsGram, 20 * count);
      expect(intake.totalFatsGram, 12 * count);
      expect(intake.totalProteinsGram, 15 * count);
    });
  }

  for (final unit in ['g', 'ml']) {
    test('100 $unit reference scales consumed quantity', () {
      final food = create(false, unit);
      expect(food.hasServingValues, isFalse);
      expect(food.isPortionBased, isFalse);
      final intake = IntakeEntity(
          id: 'test',
          unit: unit,
          amount: 150,
          type: IntakeTypeEntity.lunch,
          meal: food,
          dateTime: DateTime(2026, 10, 24));
      expect(intake.totalKcal, 375);
      expect(intake.totalProteinsGram, 22.5);
    });
  }

  test(
      'existing weighted portions in recents are not treated as weightless portions',
      () {
    final food = create(false, 'g')
        .copyWith(servingQuantity: 150, servingUnit: 'g', mealUnit: 'serving');
    expect(food.isPortionBased, isFalse);
  });
}
