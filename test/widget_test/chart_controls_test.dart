import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_controls.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  for (final style in ChartSelectorStyle.values) {
    testWidgets('chart selector updates its choice: $style', (tester) async {
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: StatefulBuilder(
        builder: (_, setState) => ChartSelector(
            labels: const ['7 j', '14 j'],
            selectedIndex: selected,
            style: style,
            onSelected: (index) => setState(() => selected = index)),
      ))));
      if (style == ChartSelectorStyle.dropdown) {
        await tester.tap(find.text('7 j'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('14 j').last);
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    });
  }
  for (final inverse in [false, true]) {
    testWidgets('chart tooltip keeps date, values and units, inverse=$inverse',
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
            body: ChartTooltip(
                date: DateTime(2026, 11, 6),
                lines:
                    inverse ? const ['72,5 kg', '1 500 kcal'] : const ['72,5'],
                unit: inverse ? null : 'kg',
                inverse: inverse)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('72,5 kg'), findsOneWidget);
      if (inverse) expect(find.text('1 500 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
