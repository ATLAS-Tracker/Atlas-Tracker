import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_summary_card.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/profile/student_macros_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Widget dashboard(double consumed, double goal) => DashboardWidget(
      totalKcalSupplied: consumed,
      dailyStepCount: 0,
      totalKcalDaily: goal,
      totalKcalLeft: goal - consumed,
      totalCarbsIntake: 200,
      totalFatsIntake: 60,
      totalProteinsIntake: 120,
      totalCarbsGoal: 250,
      totalFatsGoal: 60,
      totalProteinsGoal: 120,
      userWeight: null,
      weeklyWeightDelta: null,
      targetWeight: 84,
      userWeightGoal: UserWeightGoalEntity.maintainWeight,
    );

class MockIntake extends Mock implements IntakeEntity {}

void main() {
  testWidgets('diary sums displayed meals instead of stale stored totals',
      (tester) async {
    final intake = MockIntake();
    when(() => intake.totalKcal).thenReturn(1993);
    when(() => intake.totalCarbsGram).thenReturn(200);
    when(() => intake.totalFatsGram).thenReturn(60);
    when(() => intake.totalProteinsGram).thenReturn(120);
    await tester.pumpWidget(app(DiarySummaryCard(
      trackedDay: TrackedDayEntity(
          day: DateTime(2026, 11, 2), calorieGoal: 2201, caloriesTracked: 2124),
      intakes: [intake],
      selectedDayWeight: null,
      homeState: null,
    )));
    expect(find.textContaining('1\u202f993 / 2\u202f201'), findsOneWidget);
    expect(find.textContaining('2\u202f124'), findsNothing);
  });
  testWidgets('home rounds consumption and subtracts the displayed integers',
      (tester) async {
    await tester.pumpWidget(app(dashboard(899.6, 2140)));
    expect(find.textContaining('1\u202f240'), findsOneWidget);
    expect(find.textContaining('900 / 2\u202f140'), findsOneWidget);
  });

  testWidgets(
      'home shows a calorie overrun and hides the profile weight target',
      (tester) async {
    await tester.pumpWidget(app(dashboard(2600, 2000)));
    expect(find.text('+600 kcal au-dessus'), findsOneWidget);
    expect(find.textContaining('84'), findsNothing);
    expect(find.byKey(const ValueKey('energy-overflow')), findsOneWidget);
  });

  testWidgets('diary shows the same calorie overrun', (tester) async {
    await tester.pumpWidget(app(DiarySummaryCard(
      trackedDay: TrackedDayEntity(
          day: DateTime(2026, 11, 2), calorieGoal: 2000, caloriesTracked: 2600),
      selectedDayWeight: null,
      homeState: null,
    )));
    expect(find.text('+600 kcal au-dessus'), findsOneWidget);
    expect(find.byKey(const ValueKey('energy-overflow')), findsOneWidget);
  });

  testWidgets('coach exposes calorie overruns without toggling to percentages',
      (tester) async {
    await tester.pumpWidget(app(const SizedBox(
        width: 200,
        height: 200,
        child: StudentEnergyCard(consumed: 2600, goal: 2000))));
    await tester.pumpAndSettle();
    expect(find.text('+600 kcal au-dessus'), findsOneWidget);
  });
  testWidgets(
      'calendar rejects a half-filled day and leaves empty days unmarked',
      (tester) async {
    await tester.pumpWidget(app(Builder(builder: (context) {
      TrackedDayEntity day(double kcal) => TrackedDayEntity(
          day: DateTime(2026, 11, 2), calorieGoal: 2000, caloriesTracked: kcal);
      expect(day(1050).getCalendarDayRatingColor(context),
          Theme.of(context).colorScheme.error);
      expect(day(2000).getCalendarDayRatingColor(context),
          Theme.of(context).colorScheme.primary);
      expect(day(0).getCalendarDayRatingColor(context), isNull);
      return const SizedBox();
    })));
  });
}
