import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/auth/check_subscription.dart';
// Added for resume macro refresh
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedPageIndex = 0;

  late List<Widget> _bodyPages;
  late List<PreferredSizeWidget> _appbarPages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    // 1) Ensure subscription is still valid
    final service = SubscriptionService(locator<SupabaseClient>());
    final isSubscribed = await service.checkAndEnforceSubscription(context);

    if (!mounted) return; // guard after async gap

    if (!isSubscribed) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // 2) Refresh macro goals from coach and update tracked days
    try {
      final user = await locator.get<GetUserUsecase>().getUserData();
      if (user.role == UserRoleEntity.student) {
        await locator.get<AddMacroGoalUsecase>().addMacroGoalFromCoach();

        // Notify key views to refresh
        locator<HomeBloc>().add(const LoadItemsEvent());
        locator<DiaryBloc>().add(const LoadDiaryYearEvent());
        locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
      }
    } catch (_) {
      // Silently ignore on resume to avoid disrupting UX
    }
  }

  @override
  void didChangeDependencies() {
    _bodyPages = [
      const HomePage(),
      const DiaryPage(),
      const ProfilePage(),
    ];
    _appbarPages = [
      const HomeAppbar(),
      MainAppbar(
          title: S.of(context).diaryLabel,
          iconData: Icons.calendar_month_outlined),
      MainAppbar(
          title: S.of(context).profileLabel, iconData: Icons.account_circle)
    ];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appbarPages[_selectedPageIndex],
      body: _bodyPages[_selectedPageIndex],
      floatingActionButton: null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: _setPage,
        destinations: [
          NavigationDestination(
              icon: _selectedPageIndex == 0
                  ? const Icon(Icons.home)
                  : const Icon(Icons.home_outlined),
              label: S.of(context).homeLabel),
          NavigationDestination(
              icon: _selectedPageIndex == 1
                  ? const Icon(Icons.calendar_month)
                  : const Icon(Icons.calendar_month_outlined),
              label: S.of(context).diaryLabel),
          NavigationDestination(
              icon: _selectedPageIndex == 2
                  ? const Icon(Icons.account_circle)
                  : const Icon(Icons.account_circle_outlined),
              label: S.of(context).profileLabel)
        ],
      ),
    );
  }

  void _setPage(int selectedIndex) {
    setState(() {
      _selectedPageIndex = selectedIndex;
    });
  }
}
