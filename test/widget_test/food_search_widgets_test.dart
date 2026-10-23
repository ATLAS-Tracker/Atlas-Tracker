import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  Widget app(Widget child, {bool dark = false, RouteFactory? route}) =>
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        theme:
            ThemeData(colorScheme: dark ? darkColorScheme : lightColorScheme),
        onGenerateRoute: route,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(20), child: child)),
      );

  testWidgets('search keeps text on rebuild and retains scanner and submit',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final query = ValueNotifier('');
    addTearDown(query.dispose);
    final searches = <String>[];
    var scans = 0;
    Widget search() => MealSearchBar(
        searchStringListener: query,
        onSearchSubmit: searches.add,
        onBarcodePressed: () => scans++);
    await tester.pumpWidget(app(search()));
    await tester.enterText(find.byType(TextField), 'Poulet');
    await tester.pumpWidget(app(search()));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Poulet');
    expect(query.value, 'Poulet');
    expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'Rechercher');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
    expect(searches, ['Poulet', 'Poulet']);
    expect(scans, 1);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'food result fits narrow screen and keeps detail arguments, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final day = DateTime(2026, 10, 23);
      final meal = MealEntity(
          code: 'test',
          name: 'Un aliment avec un nom assez long pour plusieurs lignes',
          brands: 'Une marque avec un nom long',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: '100 g',
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom);
      RouteSettings? requested;
      await tester.pumpWidget(app(
          SingleChildScrollView(
              child: MealItemCard(
                  day: day,
                  mealEntity: meal,
                  addMealType: AddMealType.lunchType,
                  usesImperialUnits: false)),
          dark: dark, route: (settings) {
        requested = settings;
        return MaterialPageRoute<void>(builder: (_) => const Scaffold());
      }));
      await tester.pumpAndSettle();
      expect(find.text('100 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(requested?.name, NavigationOptions.mealDetailRoute);
      final arguments = requested!.arguments as MealDetailScreenArguments;
      expect(arguments.mealEntity, same(meal));
      expect(arguments.day, day);
    });
  }
}
