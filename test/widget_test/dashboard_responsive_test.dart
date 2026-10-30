import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('three-digit macros fit at width=$width scale=$scale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: ThemeData(textTheme: appTextTheme),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: DashboardWidget(
            totalKcalSupplied: 2500,
            dailyStepCount: 500,
            totalKcalDaily: 2200,
            totalKcalLeft: -300,
            totalCarbsIntake: 220,
            totalFatsIntake: 110,
            totalProteinsIntake: 155,
            totalCarbsGoal: 250,
            totalFatsGoal: 70,
            totalProteinsGoal: 150,
            userWeight: UserWeightEntity(
                id: 'weight-test', weight: 105.5, date: DateTime(2026, 10, 23)),
            weeklyWeightDelta: null,
            targetWeight: 84,
            userWeightGoal: UserWeightGoalEntity.loseWeight,
            usesImperialUnits: false,
          ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('macro-energy-legend')), findsNothing);
        await tester.tap(find.byType(MacroEnergyBar));
        await tester.pumpAndSettle();
        expect(
            find.byKey(const ValueKey('macro-energy-legend')), findsOneWidget);
        for (final share in ['35 %', '40 %', '25 %']) {
          expect(find.text(share), findsOneWidget);
        }
        expect(find.byType(AlertDialog), findsNothing);
        for (var i = 0; i < 3; i++) {
          expect(find.byKey(ValueKey('legend-dot-$i')), findsOneWidget);
        }
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('macro-energy-legend')), findsNothing);
        final number = tester.widget<Text>(find.text('220 / 250 g'));
        expect(number.maxLines, 1);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        final segments = [
          for (var i = 0; i < 3; i++)
            tester.getSize(find.byKey(ValueKey('energy-segment-$i'))).width,
        ];
        final totalWidth = segments.reduce((a, b) => a + b);
        // The goal is exceeded: the full bar retains the energy proportions.
        expect(segments[0] / totalWidth, closeTo(880 / 2490, 0.001));
        expect(segments[1] / totalWidth, closeTo(990 / 2490, 0.001));
        expect(segments[2] / totalWidth, closeTo(620 / 2490, 0.001));
      });
    }
  }
}
