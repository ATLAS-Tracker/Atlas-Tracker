import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets('DashboardWidget displays summary data',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: null,
          targetWeight: 84,
          userWeightGoal: UserWeightGoalEntity.gainWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('1000'), findsOneWidget);
    expect(find.textContaining('84.0'), findsOneWidget);
    expect(find.text(S.current.goalGainWeightDashboard), findsOneWidget);
    expect(find.text('200 / 250 g'), findsOneWidget);
    expect(find.text('50 / 60 g'), findsOneWidget);
    expect(find.text('100 / 120 g'), findsOneWidget);
  });

  testWidgets('DashboardWidget shows rounded loss trend as successful',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: -0.199,
          targetWeight: 80,
          userWeightGoal: UserWeightGoalEntity.loseWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final trendFinder = find.text('- 0.2 kg');
    expect(trendFinder, findsOneWidget);

    final trendText = tester.widget<Text>(trendFinder);
    expect(trendText.style?.color, lunchColor);
  });

  testWidgets('DashboardWidget displays remaining weight without signed prefix',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: UserWeightEntity(
            id: 'today-weight',
            weight: 5,
            date: DateTime(2026, 6, 15),
          ),
          weeklyWeightDelta: null,
          targetWeight: 4,
          userWeightGoal: UserWeightGoalEntity.loseWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final textValues = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .toList();
    final targetText = textValues.singleWhere(
      (text) => text.contains('Target 4.0 kg'),
    );

    expect(targetText, contains('1.0'));
    expect(targetText, contains('kg'));
    expect(targetText, contains('remaining'));
    expect(targetText, isNot(contains('- 1.0')));
    expect(targetText, isNot(contains('-\u00A01.0')));
  });

  testWidgets('DashboardWidget uses trend sign only for weight loss goal',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: 0.1,
          targetWeight: 80,
          userWeightGoal: UserWeightGoalEntity.loseWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final trendFinder = find.text('+ 0.1 kg');
    expect(trendFinder, findsOneWidget);

    final trendText = tester.widget<Text>(trendFinder);
    final errorColor = Theme.of(
      tester.element(find.byType(DashboardWidget)),
    ).colorScheme.error;
    expect(trendText.style?.color, errorColor);
  });

  testWidgets('DashboardWidget uses trend sign only for weight gain goal',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: 0.1,
          targetWeight: 90,
          userWeightGoal: UserWeightGoalEntity.gainWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final trendFinder = find.text('+ 0.1 kg');
    expect(trendFinder, findsOneWidget);

    final trendText = tester.widget<Text>(trendFinder);
    expect(trendText.style?.color, lunchColor);
  });

  testWidgets('DashboardWidget keeps tolerance only for maintain weight goal',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: 0.1,
          targetWeight: 84,
          userWeightGoal: UserWeightGoalEntity.maintainWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final trendFinder = find.text('+ 0.1 kg');
    expect(trendFinder, findsOneWidget);

    final trendText = tester.widget<Text>(trendFinder);
    expect(trendText.style?.color, lunchColor);
  });

  testWidgets('DashboardWidget opens weight screen when weight card is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      routes: {
        NavigationOptions.addWeightRoute: (_) => const Scaffold(
              body: Text('weight-route-opened'),
            ),
      },
      home: Scaffold(
        body: DashboardWidget(
          totalKcalSupplied: 1500,
          dailyStepCount: 500,
          totalKcalDaily: 2000,
          totalKcalLeft: 1000,
          totalCarbsIntake: 200,
          totalFatsIntake: 50,
          totalProteinsIntake: 100,
          totalCarbsGoal: 250,
          totalFatsGoal: 60,
          totalProteinsGoal: 120,
          userWeight: null,
          weeklyWeightDelta: null,
          targetWeight: 84,
          userWeightGoal: UserWeightGoalEntity.maintainWeight,
          usesImperialUnits: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.current.currentWeightLabel));
    await tester.pumpAndSettle();

    expect(find.text('weight-route-opened'), findsOneWidget);
  });
}
