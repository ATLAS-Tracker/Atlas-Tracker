import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';

void main() {
  testWidgets('previous week navigation preserves the selected weekday',
      (WidgetTester tester) async {
    final selectedDate = await _tapWeekNavigation(
      tester,
      initialSelectedDate: DateTime(2026, 6, 18),
      icon: Icons.chevron_left_rounded,
    );

    expect(selectedDate, DateTime(2026, 6, 11));
  });

  testWidgets('next week navigation preserves the selected weekday',
      (WidgetTester tester) async {
    final selectedDate = await _tapWeekNavigation(
      tester,
      initialSelectedDate: DateTime(2026, 6, 18),
      icon: Icons.chevron_right_rounded,
    );

    expect(selectedDate, DateTime(2026, 6, 25));
  });
}

Future<DateTime?> _tapWeekNavigation(
  WidgetTester tester, {
  required DateTime initialSelectedDate,
  required IconData icon,
}) async {
  DateTime? selectedDate;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DiaryTableCalendar(
          trackedDaysMap: const <String, TrackedDayEntity>{},
          onDateSelected: (
            DateTime date,
            Map<String, TrackedDayEntity> trackedDaysMap,
          ) {
            selectedDate = date;
          },
          calendarDurationDays: const Duration(days: 356),
          currentDate: initialSelectedDate,
          selectedDate: initialSelectedDate,
          focusedDate: initialSelectedDate,
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();

  return selectedDate;
}
