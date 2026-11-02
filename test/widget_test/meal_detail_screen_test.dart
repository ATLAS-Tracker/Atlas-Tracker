import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockAddIntake extends Mock implements AddIntakeUsecase {}

class MockAddTracked extends Mock implements AddTrackedDayUsecase {}

class MockGetKcal extends Mock implements GetKcalGoalUsecase {}

class MockGetMacro extends Mock implements GetMacroGoalUsecase {}

class MockSearchByBarcode extends Mock
    implements SearchProductByBarcodeUseCase {}

void main() {
  late MealDetailBloc bloc;
  tearDown(() async {
    await bloc.close();
    await locator.reset();
  });

  testWidgets(
      '26g serving label shows count and weight, grams hide portion count',
      (tester) async {
    bloc = MealDetailBloc(
        MockAddIntake(), MockAddTracked(), MockGetKcal(), MockGetMacro());
    locator.registerSingleton<MealDetailBloc>(bloc);
    final meal = MealEntity.empty().copyWith(
      name: 'Cookie Milka',
      mealUnit: 'g',
      servingQuantity: 26,
      servingUnit: 'g',
      servingSize: '26g',
      nutriments: const MealNutrimentsEntity(
          energyKcalPerQuantity: 500,
          carbohydratesPerQuantity: 60,
          fatPerQuantity: 25,
          proteinsPerQuantity: 6,
          sugarsPerQuantity: null,
          saturatedFatPerQuantity: null,
          fiberPerQuantity: null,
          mealOrRecipe: MealOrRecipeEntity.meal),
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(
              arguments: MealDetailScreenArguments(
                  meal, IntakeTypeEntity.lunch, DateTime(2026, 10, 25), false)),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 portion (de 26 g)'), findsOneWidget);
    expect(find.text('Portion (26 g)'), findsOneWidget);
    expect(find.text('26g'), findsNothing);
    expect(find.text('130 kcal'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pumpAndSettle();
    expect(find.text('2 portions (de 52 g)'), findsOneWidget);
    expect(find.text('260 kcal'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.gramUnit).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '26');
    await tester.pumpAndSettle();
    expect(find.text('26 g'), findsOneWidget);
    expect(find.textContaining('portion'), findsNothing);
    expect(find.text('130 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final keyboard in [false, true]) {
    testWidgets(
        'detail preserves information and quantity updates on narrow screen, keyboard=$keyboard',
        (tester) async {
      bloc = MealDetailBloc(
          MockAddIntake(), MockAddTracked(), MockGetKcal(), MockGetMacro());
      locator.registerSingleton<MealDetailBloc>(bloc);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      if (keyboard) tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      addTearDown(tester.view.reset);
      final day = DateTime(2026, 10, 24);
      final meal = MealEntity(
          code: 'test',
          name: 'Un aliment avec un nom assez long',
          brands: 'Marque de test',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: null,
          servingSize: null,
          nutriments: const MealNutrimentsEntity(
              energyKcalPerQuantity: 250,
              carbohydratesPerQuantity: 20,
              fatPerQuantity: 12,
              proteinsPerQuantity: 15,
              sugarsPerQuantity: 5,
              saturatedFatPerQuantity: 2,
              fiberPerQuantity: 3,
              mealOrRecipe: MealOrRecipeEntity.meal),
          source: MealSourceEntity.custom);
      RouteSettings? requested;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        theme: ThemeData(
            colorScheme: keyboard ? darkColorScheme : lightColorScheme),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        onGenerateRoute: (settings) {
          if (settings.name == NavigationOptions.editMealRoute) {
            requested = settings;
            return MaterialPageRoute<void>(builder: (_) => const Scaffold());
          }
          return MaterialPageRoute<void>(
              settings: RouteSettings(
                  arguments: MealDetailScreenArguments(
                      meal, IntakeTypeEntity.lunch, day, false)),
              builder: (_) => const MealDetailScreen());
        },
      ));
      await tester.pumpAndSettle();
      expect(bloc.state.totalKcal, 250);
      expect(find.text('Marque de test'), findsOneWidget);
      final input = find.byType(TextFormField);
      await tester.ensureVisible(input);
      await tester.enterText(input, '150');
      await tester.pumpAndSettle();
      expect(bloc.state.totalKcal, 375);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('375 kcal'), findsWidgets);
      expect(bloc.state.totalProtein, 22.5);
      expect(tester.takeException(), isNull);
      if (!keyboard) {
        expect(find.text(S.current.fiberLabel), findsNothing);
        final nutrition = find.byType(ExpansionTile);
        await tester.scrollUntilVisible(nutrition, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text(S.current.nutritionInfoLabel));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text(S.current.fiberLabel), 250,
            scrollable: find.byType(Scrollable).first);
        expect(find.text(S.current.fiberLabel), findsOneWidget);
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        final arguments = requested!.arguments as EditMealScreenArguments;
        expect(arguments.mealEntity, same(meal));
        expect(arguments.day, day);
      }
    });
  }

  testWidgets(
      'OFF search result gets its serving from the full product and keeps it '
      'when the unit menu opens', (tester) async {
    bloc = MealDetailBloc(
        MockAddIntake(), MockAddTracked(), MockGetKcal(), MockGetMacro());
    locator.registerSingleton<MealDetailBloc>(bloc);
    // Search results carry the package size (300 g) but no serving.
    final searchResult = MealEntity.empty().copyWith(
      code: '7622210450029',
      name: 'Prince',
      mealQuantity: '300',
      mealUnit: 'g',
      source: MealSourceEntity.off,
      nutriments: const MealNutrimentsEntity(
          energyKcalPerQuantity: 475,
          carbohydratesPerQuantity: 70,
          fatPerQuantity: 19,
          proteinsPerQuantity: 6,
          sugarsPerQuantity: null,
          saturatedFatPerQuantity: null,
          fiberPerQuantity: null,
          mealOrRecipe: MealOrRecipeEntity.meal),
    );
    final searchByBarcode = MockSearchByBarcode();
    when(() => searchByBarcode.searchProductByBarcode(any())).thenAnswer(
        (_) async => searchResult.copyWith(
            servingQuantity: 20, servingUnit: 'g', servingSize: '20 g'));
    locator.registerSingleton<SearchProductByBarcodeUseCase>(searchByBarcode);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(
              arguments: MealDetailScreenArguments(searchResult,
                  IntakeTypeEntity.lunch, DateTime(2026, 11, 2), false)),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 portion (de 20 g)'), findsOneWidget);
    expect(find.text('95 kcal'), findsOneWidget);

    // Opening the menu re-runs didChangeDependencies: the serving must stay.
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.gramUnit).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Portion (20 g)'), findsWidgets);
  });

  testWidgets('OFF product without serving defaults to 100 g, not the jar',
      (tester) async {
    bloc = MealDetailBloc(
        MockAddIntake(), MockAddTracked(), MockGetKcal(), MockGetMacro());
    locator.registerSingleton<MealDetailBloc>(bloc);
    final nutella = MealEntity.empty().copyWith(
      code: '3017620422003',
      name: 'Nutella',
      mealQuantity: '1000',
      mealUnit: 'g',
      source: MealSourceEntity.off,
      nutriments: const MealNutrimentsEntity(
          energyKcalPerQuantity: 539,
          carbohydratesPerQuantity: 57,
          fatPerQuantity: 31,
          proteinsPerQuantity: 6,
          sugarsPerQuantity: null,
          saturatedFatPerQuantity: null,
          fiberPerQuantity: null,
          mealOrRecipe: MealOrRecipeEntity.meal),
    );
    final searchByBarcode = MockSearchByBarcode();
    when(() => searchByBarcode.searchProductByBarcode(any()))
        .thenAnswer((_) async => nutella);
    locator.registerSingleton<SearchProductByBarcodeUseCase>(searchByBarcode);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(
              arguments: MealDetailScreenArguments(nutella,
                  IntakeTypeEntity.lunch, DateTime(2026, 11, 2), false)),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('539 kcal'), findsOneWidget);
  });
}
