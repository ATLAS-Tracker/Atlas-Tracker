import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'journal_sync_engine.dart';
import 'profile_remote_sync.dart';

/// Runs after the local UI is available. Each remote request has a deadline;
/// failure keeps local data and the durable synchronization queue intact.
Future<void> synchronizeUserData(SupabaseClient client) async {
  final owner = client.auth.currentUser?.id;
  if (owner == null) return;
  bool owns() =>
      client.auth.currentUser?.id == owner &&
      locator<HiveDBProvider>().activeUserId == owner;
  try {
    await syncProfileFromSupabase(client);
    if (!owns()) return;
    final user = await locator<GetUserUsecase>().getUserData();
    if (user.role == UserRoleEntity.student) {
      try {
        await locator<AddMacroGoalUsecase>()
            .addMacroGoalFromCoach()
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        Logger('StartupUserSync')
            .warning('Coach goals deferred: ${error.runtimeType}');
      }
    }
    if (!owns()) return;
    await locator<JournalSyncEngine>().sync();
    if (!owns()) return;
    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(const RefreshCalendarDayEvent());
    locator<ProfileBloc>().add(LoadProfileEvent());
  } catch (error, stack) {
    Logger('StartupUserSync').warning(
        'Remote refresh deferred; local UI remains available.', error, stack);
  }
}
