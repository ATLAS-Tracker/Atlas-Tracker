import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/presentation/refresh_journal.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

class MockHome extends Mock implements HomeBloc {}

class MockDiary extends Mock implements DiaryBloc {}

class MockCalendar extends Mock implements CalendarDayBloc {}

void main() {
  late MockHome home;
  late MockDiary diary;
  late MockCalendar calendar;
  setUp(() {
    home = MockHome();
    diary = MockDiary();
    calendar = MockCalendar();
    locator.registerSingleton<HomeBloc>(home);
    locator.registerSingleton<DiaryBloc>(diary);
    locator.registerSingleton<CalendarDayBloc>(calendar);
  });
  tearDown(() => locator.reset());
  test('refresh keeps the current calendar day and loads Home and Diary', () {
    refreshJournalViews();
    verify(() => home.add(const LoadItemsEvent())).called(1);
    verify(() => diary.add(const LoadDiaryYearEvent())).called(1);
    verify(() => calendar.add(const RefreshCalendarDayEvent())).called(1);
    verifyNoMoreInteractions(home);
    verifyNoMoreInteractions(diary);
    verifyNoMoreInteractions(calendar);
  });
  test('dated refresh preserves its selected day and can omit Home', () {
    final day = DateTime(2026, 11, 6);
    refreshJournalViews(day: day, includeHome: false);
    verify(() => diary.add(const LoadDiaryYearEvent())).called(1);
    verify(() => calendar.add(LoadCalendarDayEvent(day))).called(1);
    verifyZeroInteractions(home);
  });
}
