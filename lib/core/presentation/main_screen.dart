import 'dart:async';
import 'package:opennutritracker/services/nutrition_widget_actions.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/profile/coach_students_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/auth/check_subscription.dart';
// Added for resume macro refresh
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/features/sync/startup_user_sync.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedPageIndex = 0;
  bool _isCoach = false;
  final _widgetActions = NutritionWidgetActions();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _widgetActions.start(_openWidgetAction);
    });
    unawaited(synchronizeUserData(locator<SupabaseClient>()));
    locator.get<GetUserUsecase>().getUserData().then((user) {
      if (mounted && user.role == UserRoleEntity.coach) {
        setState(() => _isCoach = true);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _widgetActions.dispose();
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

    unawaited(synchronizeUserData(locator<SupabaseClient>()));
  }

  void _openWidgetAction(String action) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    // Fixed meal until widget meal-time preferences are introduced.
    const meal = AddMealType.breakfastType;
    final day = DateTime.now();
    if (action == 'scan') {
      navigator.pushNamed(NavigationOptions.scannerRoute,
          arguments: ScannerScreenArguments(day, meal.getIntakeType()));
    } else {
      navigator.pushNamed(NavigationOptions.addMealRoute,
          arguments:
              AddMealScreenArguments(meal, day, MealOrRecipeEntity.meal));
    }
  }

  @override
  Widget build(BuildContext context) {
    // CoachStudentsPage brings its own Scaffold/AppBar.
    final bodyPages = <Widget>[
      const HomePage(),
      const DiaryPage(),
      _isCoach ? const CoachStudentsPage() : const ProfilePage(),
    ];
    final appbarPages = <PreferredSizeWidget?>[
      const HomeAppbar(),
      MainAppbar(
          title: S.of(context).diaryLabel,
          iconData: Icons.calendar_month_outlined),
      _isCoach
          ? null
          : MainAppbar(
              title: S.of(context).profileLabel, iconData: Icons.account_circle)
    ];
    return Scaffold(
      appBar: appbarPages[_selectedPageIndex],
      body: IndexedStack(index: _selectedPageIndex, children: bodyPages),
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
          _isCoach
              ? NavigationDestination(
                  icon: _selectedPageIndex == 2
                      ? const Icon(Icons.groups)
                      : const Icon(Icons.groups_outlined),
                  label: S.of(context).myStudentsTitle)
              : NavigationDestination(
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
