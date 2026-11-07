import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';

import '../fixture/intake_for_recipe_fixtures.dart';

class MockGetRecipeUsecase extends Mock implements GetRecipeUsecase {}

void main() {
  late CreateMealBloc bloc;
  late MockGetRecipeUsecase mockGetRecipeUsecase;

  final mockIntakeList = [
    IntakeForRecipeFixtures.chicken,
    IntakeForRecipeFixtures.rice,
  ];

  setUp(() {
    mockGetRecipeUsecase = MockGetRecipeUsecase();
    bloc = CreateMealBloc(mockGetRecipeUsecase);
  });

  test('initial state is correct', () {
    expect(bloc.state, const CreateMealState());
  });

  blocTest<CreateMealBloc, CreateMealState>(
    'emits [isOnCreateMealScreen: true] when InitializeCreateMealEvent is added',
    build: () => bloc,
    act: (bloc) => bloc.add(const InitializeCreateMealEvent()),
    expect: () => [
      const CreateMealState(isOnCreateMealScreen: true),
    ],
  );

  blocTest<CreateMealBloc, CreateMealState>(
    'emits [isOnCreateMealScreen: false] when ExitCreateMealScreenEvent is added',
    build: () => bloc,
    seed: () => const CreateMealState(isOnCreateMealScreen: true),
    act: (bloc) => bloc.add(const ExitCreateMealScreenEvent()),
    expect: () => [
      const CreateMealState(isOnCreateMealScreen: false),
    ],
  );

  test('totals are correctly computed', () async {
    bloc.add(SetIntakeListFromRecipeEvent(mockIntakeList));

    await expectLater(
      bloc.stream,
      emits(
        predicate<CreateMealState>((state) {
          expect(state.intakeList, mockIntakeList);
          expect(state.totalProteins, closeTo(34.75, 0.001));
          expect(state.totalCarbs, closeTo(42.0, 0.001));
          expect(state.totalFats, closeTo(4.5, 0.001));
          return true;
        }),
      ),
    );
  });
  test('converted recipe ingredients are stored in grams rather than portions',
      () async {
    await bloc.addIntake('serving', '60', IntakeTypeEntity.lunch,
        IntakeForRecipeFixtures.chicken.meal!, DateTime(2026, 11, 3));
    final ingredient = bloc.getListOfIntakeForRecipeEntity().single;
    expect(ingredient.unit, 'g');
    expect(ingredient.amount, 60);
    expect(bloc.computeMacros()['totalKcal'], closeTo(99, 0.001));
    await bloc.close();
  });
}
