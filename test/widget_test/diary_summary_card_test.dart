import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_summary_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });

  for (final dark in [false, true]) {
    for (final populated in [false, true]) {
      testWidgets(
          'journal summary fits enlarged text, dark=$dark populated=$populated',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var edited = false;
        final day = DateTime(2026, 10, 23);
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            textTheme: appTextTheme,
            colorScheme: dark ? darkColorScheme : lightColorScheme,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
              body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: DiarySummaryCard(
              trackedDay: populated
                  ? TrackedDayEntity(
                      day: day,
                      calorieGoal: 2200,
                      caloriesTracked: 2500,
                      carbsTracked: 220,
                      carbsGoal: 250,
                      fatTracked: 100,
                      fatGoal: 80,
                      proteinTracked: 150,
                      proteinGoal: 150,
                    )
                  : null,
              selectedDayWeight: populated
                  ? UserWeightEntity(
                      id: 'weight',
                      weight: 78.4,
                      date: day,
                    )
                  : null,
              weeklyWeightDelta: populated ? -0.6 : null,
              homeState: null,
              onEditWeight: () => edited = true,
            ),
          )),
        ));
        await tester.pumpAndSettle();
        expect(find.text('220 / 250 g'), findsNothing);
        await tester.tap(find.text(S.current.kcalMacrosLabel));
        await tester.pumpAndSettle();
        if (populated) {
          expect(find.text('220 / 250 g'), findsOneWidget);
          expect(
              find.descendant(
                  of: find.byType(AtlasBrandPanel),
                  matching: find.text('78,4 kg')),
              findsOneWidget);
        }
        await tester.tap(find.text(S.current.kcalMacrosLabel));
        await tester.pumpAndSettle();
        expect(find.text('220 / 250 g'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byKey(const ValueKey('macro-energy-legend')), findsNothing);
        await tester.tap(find.byType(MacroEnergyBar));
        await tester.pumpAndSettle();
        expect(
            find.byKey(const ValueKey('macro-energy-legend')), findsOneWidget);
        expect(find.text(populated ? '37 %' : '0 %'),
            populated ? findsOneWidget : findsNWidgets(3));
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        for (var i = 0; i < 3; i++) {
          expect(find.byKey(ValueKey('legend-dot-$i')), findsOneWidget);
        }
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('macro-energy-legend')), findsNothing);
        await tester.ensureVisible(find.byTooltip(S.current.editWeightLabel));
        await tester.tap(find.byTooltip(S.current.editWeightLabel));
        expect(edited, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
