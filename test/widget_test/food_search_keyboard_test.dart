import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockProductsBloc extends Mock implements ProductsBloc {}

class MockRecentMealBloc extends Mock implements RecentMealBloc {}

class MockRecipeSearchBloc extends Mock implements RecipeSearchBloc {}

class MockAddMealBloc extends Mock implements AddMealBloc {}

void main() {
  tearDown(() => locator.reset());
  for (final keyboardHeight in [360.0, 480.0]) {
    testWidgets(
        'food search fits with keyboard=$keyboardHeight and enlarged text while loading',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
      addTearDown(tester.view.reset);
      final products = MockProductsBloc();
      when(() => products.state).thenReturn(ProductsLoadingState());
      when(() => products.stream)
          .thenAnswer((_) => const Stream<ProductsState>.empty());
      final recent = MockRecentMealBloc();
      when(() => recent.state).thenReturn(RecentMealLoadingState());
      when(() => recent.stream)
          .thenAnswer((_) => const Stream<RecentMealState>.empty());
      final recipes = MockRecipeSearchBloc();
      when(() => recipes.state).thenReturn(RecipeLoadingState());
      when(() => recipes.stream)
          .thenAnswer((_) => const Stream<RecipeSearchState>.empty());
      final add = MockAddMealBloc();
      when(() => add.state).thenReturn(const AddMealLoadedState());
      when(() => add.stream)
          .thenAnswer((_) => const Stream<AddMealState>.empty());
      locator.registerSingleton<ProductsBloc>(products);
      locator.registerSingleton<RecentMealBloc>(recent);
      locator.registerSingleton<RecipeSearchBloc>(recipes);
      locator.registerSingleton<AddMealBloc>(add);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
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
              arguments: AddMealScreenArguments(AddMealType.lunchType,
                  DateTime(2026, 10, 23), MealOrRecipeEntity.meal)),
          builder: (_) => const AddMealScreen(),
        ),
      ));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'poulet');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });
  }
}
