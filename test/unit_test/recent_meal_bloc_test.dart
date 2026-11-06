import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';

class MockGetIntake extends Mock implements GetIntakeUsecase {}

class MockGetRecipe extends Mock implements GetRecipeUsecase {}

void main() {
  for (final query in ['boeuf', 'bœuf', ' BŒUF ']) {
    test('recent food search folds ligatures: $query', () async {
      final intakes = MockGetIntake();
      final recipes = MockGetRecipe();
      final foods = [
        MealEntity.empty().copyWith(code: 'a', name: 'Boeuf'),
        MealEntity.empty().copyWith(code: 'b', name: 'Bœuf'),
        MealEntity.empty().copyWith(code: 'c', name: 'Poulet', brands: 'Bœuf'),
        MealEntity.empty().copyWith(code: 'd', name: 'Riz'),
      ];
      when(() => intakes.getRecentIntake()).thenAnswer((_) async => []);
      when(() => recipes.getSavedFoods()).thenAnswer((_) async => foods);
      final bloc = RecentMealBloc(intakes, recipes);
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((s) => s is RecentMealLoadedState);
      bloc.add(LoadRecentMealEvent(searchString: query));
      expect(
          (await loaded as RecentMealLoadedState).recentMeals, foods.take(3));
    });
  }

  test('saved food keeps its last intake and unconsumed food has no history',
      () async {
    final intakes = MockGetIntake();
    final recipes = MockGetRecipe();
    final food =
        MealEntity.empty().copyWith(code: 'lardons', mealQuantity: '200');
    final unused = MealEntity.empty().copyWith(code: 'unused');
    final last = IntakeEntity(
        id: 'last',
        amount: 160,
        unit: 'g',
        meal: food,
        type: IntakeTypeEntity.lunch,
        dateTime: DateTime(2026, 11, 6));
    when(() => intakes.getRecentIntake()).thenAnswer((_) async => [last]);
    when(() => recipes.getSavedFoods()).thenAnswer((_) async => [food, unused]);
    final bloc = RecentMealBloc(intakes, recipes);
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((s) => s is RecentMealLoadedState);
    bloc.add(const LoadRecentMealEvent(searchString: ''));
    final state = await loaded as RecentMealLoadedState;
    expect(state.recentMeals, [food, unused]);
    expect(state.lastIntakes['lardons'], same(last));
    expect(state.lastIntakes['lardons']!.amount, 160);
    expect(state.lastIntakes.containsKey('unused'), isFalse);
  });
}
