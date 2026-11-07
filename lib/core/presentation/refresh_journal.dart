import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

void refreshJournalViews({DateTime? day, bool includeHome = true}) {
  locator<DiaryBloc>().add(const LoadDiaryYearEvent());
  locator<CalendarDayBloc>().add(day == null
      ? const RefreshCalendarDayEvent()
      : LoadCalendarDayEvent(day));
  if (includeHome) locator<HomeBloc>().add(const LoadItemsEvent());
}
