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
