import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/features/create_meal/create_meal_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/features/create_meal/create_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';

import '../fixture/intake_for_recipe_fixtures.dart';

class MockGetRecipeUsecase extends Mock implements GetRecipeUsecase {}

class MockHomeBloc extends Mock implements HomeBloc {}

class MockMealDetailBloc extends Mock implements MealDetailBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CreateMealBloc bloc;
  setUp(() {
    bloc = CreateMealBloc(MockGetRecipeUsecase());
    locator.registerSingleton<CreateMealBloc>(bloc);
    locator.registerSingleton<HomeBloc>(MockHomeBloc());
    locator.registerSingleton<MealDetailBloc>(MockMealDetailBloc());
  });

  tearDown(() async {
    await bloc.close();
    await locator.reset();
  });

  Widget buildWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const MealCreationScreen(),
    );
  }

  testWidgets('save button disabled with empty name or ingredients',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildWidget());

    // Initially disabled
    var button =
        tester.widget<FilledButton>(find.byKey(const ValueKey('save-recipe')));
    expect(button.onPressed, isNull);

    // Only name -> still disabled
    await tester.enterText(find.byType(TextFormField).first, 'My recipe');
    await tester.pumpAndSettle();
    button =
        tester.widget<FilledButton>(find.byKey(const ValueKey('save-recipe')));
    expect(button.onPressed, isNull);

    // Add ingredient then rebuild
    await tester.runAsync(() async {
      final ingredientsLoaded =
          bloc.stream.firstWhere((state) => state.intakeList.isNotEmpty);
      bloc.add(SetIntakeListFromRecipeEvent([IntakeForRecipeFixtures.chicken]));
      await ingredientsLoaded.timeout(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(bloc.state.intakeList, isNotEmpty);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'My recipe');

    button =
        tester.widget<FilledButton>(find.byKey(const ValueKey('save-recipe')));
    expect(button.onPressed, isNotNull);
    expect(find.text(S.current.recipeTotalsLabel), findsOneWidget);

    // Clear name -> disabled again
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();
    button =
        tester.widget<FilledButton>(find.byKey(const ValueKey('save-recipe')));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets(
      'editing preserves the recipe and supports ingredient quantity changes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ingredient = IntakeForRecipeFixtures.chicken;
    final recipe =
        RecipeEntity(meal: ingredient.meal!, ingredients: [ingredient]);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      theme: ThemeData(colorScheme: darkColorScheme),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!),
      onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(
              arguments: CreateMealScreenArguments(
                  'original-id', 'Ma recette', recipe, null)),
          builder: (_) => const MealCreationScreen()),
    ));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
    expect(find.text(S.current.editRecipeLabel), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Ma recette');
    expect(bloc.state.intakeList, hasLength(1));
    expect(
        tester.getTopLeft(find.text(S.current.recipeTotalsLabel)).dy,
        lessThan(
            tester.getTopLeft(find.text(S.current.recipeIngredientsLabel)).dy));
    expect(
        tester
            .widget<TextField>(find.descendant(
                of: find.byType(TextFormField).first,
                matching: find.byType(TextField)))
            .decoration!
            .enabledBorder,
        InputBorder.none);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

    final row = find.byKey(const ValueKey('recipe-ingredient-1'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'ingredient quantity dialog fits');
    expect(find.byType(EditDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(EditDialog))).pop(
        const EditDialogResult(
            action: EditDialogAction.updateAmount, amount: 150));
    await tester.pumpAndSettle();
    expect(bloc.state.intakeList.single.amount, 150);
    await tester.tap(find.byKey(const ValueKey('save-recipe')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'recipe save sheet fits');
    final modal = tester.widget<CalendarMealTypeSelector>(
        find.byType(CalendarMealTypeSelector));
    expect(modal.idOfRecipeToModify, 'original-id');
    expect(modal.mealName, 'Ma recette');
    Navigator.of(tester.element(find.byType(CalendarMealTypeSelector))).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
