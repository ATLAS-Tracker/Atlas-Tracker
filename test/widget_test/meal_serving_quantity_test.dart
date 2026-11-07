import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets('portion count stays separate from its weight', (tester) async {
    final meal = MealEntity.empty()
        .copyWith(mealUnit: 'serving', servingQuantity: 26, servingUnit: 'g');
    Future<void> show(double weight, String unit, double? count) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: Scaffold(
            body: MealValueUnitText(
                value: weight,
                meal: meal,
                displayUnit: unit,
                portionCount: count)),
      ));
      await tester.pumpAndSettle();
    }

    await show(26, 'g', 1);
    expect(find.text('1 portion (26 g)'), findsOneWidget);
    await show(52, 'g', 2);
    expect(find.text('2 portions (52 g)'), findsOneWidget);
    await show(26, 'g', null);
    expect(find.text('26 g'), findsOneWidget);
    expect(find.textContaining('portion'), findsNothing);
    await show(2, 'serving', null);
    expect(find.text('2 portions (52 g)'), findsOneWidget);
    await show(1, 'serving', 1);
    expect(find.text('1 portion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nutrition table uses the shared carbs, fats, proteins order',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(
          body: MealDetailNutrimentsTable(
        product: MealEntity.empty(),
      )),
    ));
    final carbs = tester.getTopLeft(find.text(S.current.carbsLabel)).dy;
    final fats = tester.getTopLeft(find.text(S.current.fatLabel)).dy;
    final proteins = tester.getTopLeft(find.text(S.current.proteinLabel)).dy;
    expect(carbs, lessThan(fats));
    expect(fats, lessThan(proteins));
  });
}
