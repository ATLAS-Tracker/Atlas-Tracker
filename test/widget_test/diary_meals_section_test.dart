import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockDiary extends Mock implements DiaryBloc {}

class MockDay extends Mock implements CalendarDayBloc {}

class MockHome extends Mock implements HomeBloc {}

class MockDetail extends Mock implements MealDetailBloc {}

void main() {
  tearDown(() => locator.reset());
  testWidgets(
      'journal meals start collapsed, expand and reset when changing date',
      (tester) async {
    final diary = MockDiary();
    when(() => diary.state).thenReturn(const DiaryLoadedState({}, false));
    when(() => diary.stream)
        .thenAnswer((_) => const Stream<DiaryState>.empty());
    final day = MockDay();
    when(() => day.state)
        .thenReturn(const CalendarDayLoaded(null, [], [], [], [], [], null));
    when(() => day.stream)
        .thenAnswer((_) => const Stream<CalendarDayState>.empty());
    final home = MockHome();
    when(() => home.state).thenReturn(HomeInitial());
    when(() => home.stream).thenAnswer((_) => const Stream<HomeState>.empty());
    locator.registerSingleton<DiaryBloc>(diary);
    locator.registerSingleton<CalendarDayBloc>(day);
    locator.registerSingleton<HomeBloc>(home);
    locator.registerSingleton<MealDetailBloc>(MockDetail());
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: const Scaffold(body: DiaryPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text(S.current.breakfastLabel), findsNothing);
    final calendar =
        tester.widget<DiaryTableCalendar>(find.byType(DiaryTableCalendar));
    final meals = find.text(S.current.mealsOfDayLabel);
    await tester.scrollUntilVisible(meals, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(meals);
    await tester.pumpAndSettle();
    await tester.tap(meals);
    await tester.pumpAndSettle();
    expect(find.text(S.current.breakfastLabel), findsOneWidget);
    expect(find.text(S.current.lunchLabel), findsOneWidget);
    expect(find.text(S.current.dinnerLabel), findsOneWidget);
    expect(find.text(S.current.snackLabel), findsOneWidget);
    calendar
        .onDateSelected(DateTime.now().subtract(const Duration(days: 1)), {});
    await tester.pumpAndSettle();
    expect(find.text(S.current.breakfastLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
