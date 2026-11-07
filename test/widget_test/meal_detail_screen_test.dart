import 'dart:async';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
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

class MockSearchByBarcode extends Mock
    implements SearchProductByBarcodeUseCase {}

void main() {
  late MealDetailBloc bloc;
  tearDown(() async {
    await locator.reset();
  });

  testWidgets(
      '26g serving label shows count and weight, grams hide portion count',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPadding);
    bloc = MealDetailBloc(MockAddIntake());
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
                  meal, IntakeTypeEntity.lunch, DateTime(2026, 10, 25))),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    final scaffoldRect = tester.getRect(find.byType(Scaffold));
    expect(scaffoldRect.top, 0, reason: 'the scaffold paints the status bar');
    final photoTap = tester.widget<GestureDetector>(find
        .ancestor(
            of: find.byIcon(Icons.fastfood_outlined),
            matching: find.byType(GestureDetector))
        .first);
    expect(photoTap.onTap, isNull,
        reason: 'a missing photo cannot open an empty viewer');
    expect(find.text('1 portion (26 g)'), findsOneWidget);
    expect(find.text('Portion (26 g)'), findsOneWidget);
    expect(find.text('26g'), findsNothing);
    expect(find.text('130 kcal'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pumpAndSettle();
    expect(find.text('2 portions (52 g)'), findsOneWidget);
    expect(find.text('260 kcal'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.gramUnit).last);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '52');
    expect(find.text('260 kcal'), findsOneWidget,
        reason: 'changing units preserves the physical quantity');
    await tester.enterText(find.byType(TextFormField), '26');
    await tester.pumpAndSettle();
    expect(find.text('26 g'), findsOneWidget);
    expect(find.textContaining('portion'), findsNothing);
    expect(find.text('130 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final selection in [(160.0, 'g'), (250.0, 'ml'), (3.0, 'serving')]) {
    testWidgets('recent card restores last quantity and unit: $selection',
        (tester) async {
      bloc = MealDetailBloc(MockAddIntake());
      locator.registerSingleton<MealDetailBloc>(bloc);
      final meal = MealEntity.empty().copyWith(
        code: 'recent-product',
        servingQuantity: selection.$2 == 'serving' ? 20 : null,
        servingUnit: selection.$2 == 'serving' ? 'g' : null,
        name: 'Produit récent',
        mealQuantity: '500',
        mealUnit: selection.$2 == 'ml' ? 'ml' : 'g',
        source: MealSourceEntity.off,
        nutriments: const MealNutrimentsEntity(
          energyKcalPerQuantity: 100,
          carbohydratesPerQuantity: 10,
          fatPerQuantity: 3,
          proteinsPerQuantity: 5,
          sugarsPerQuantity: null,
          saturatedFatPerQuantity: null,
          fiberPerQuantity: null,
          mealOrRecipe: MealOrRecipeEntity.meal,
        ),
      );
      final fullProduct = Completer<MealEntity>();
      final search = MockSearchByBarcode();
      when(() => search.searchProductByBarcode(any()))
          .thenAnswer((_) => fullProduct.future);
      locator.registerSingleton<SearchProductByBarcodeUseCase>(search);
      final lastIntake = IntakeEntity(
        id: 'previous-consumption',
        unit: selection.$2,
        amount: selection.$1,
        type: IntakeTypeEntity.dinner,
        meal: meal,
        dateTime: DateTime(2026, 11, 5),
      );
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
            body: MealItemCard(
          day: DateTime(2026, 11, 6),
          addMealType: AddMealType.lunchType,
          mealEntity: meal,
          lastIntake: lastIntake,
        )),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MealDetailScreen(),
        ),
      ));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller!
              .text,
          selection.$1.toInt().toString());
      expect(bloc.state.selectedUnit, selection.$2);
      fullProduct.complete(meal.copyWith(
          servingQuantity: 20,
          servingUnit: selection.$2 == 'ml' ? 'ml' : 'g',
          servingSize: '20 ${selection.$2 == 'ml' ? 'ml' : 'g'}'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller!
              .text,
          selection.$1.toInt().toString());
      expect(bloc.state.selectedUnit, selection.$2);
      expect(double.parse(bloc.state.totalQuantityConverted),
          selection.$1 * (selection.$2 == 'serving' ? 20 : 1));
      expect(tester.takeException(), isNull);
    });
  }

  for (final keyboard in [false, true]) {
    testWidgets(
        'detail preserves information and quantity updates on narrow screen, keyboard=$keyboard',
        (tester) async {
      bloc = MealDetailBloc(MockAddIntake());
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
                      meal, IntakeTypeEntity.lunch, day)),
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
    bloc = MealDetailBloc(MockAddIntake());
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
              arguments: MealDetailScreenArguments(
                  searchResult, IntakeTypeEntity.lunch, DateTime(2026, 11, 2))),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 portion (20 g)'), findsOneWidget);
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
    bloc = MealDetailBloc(MockAddIntake());
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
              arguments: MealDetailScreenArguments(
                  nutella, IntakeTypeEntity.lunch, DateTime(2026, 11, 2))),
          builder: (_) => const MealDetailScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('539 kcal'), findsOneWidget);
  });
}
