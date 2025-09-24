import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/main_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
// TEMP: activities screens disabled
// import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
// import 'package:opennutritracker/features/add_activity/presentation/add_activity_screen.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/features/create_meal/create_meal_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/recipe/recipe_page.dart';
import 'package:opennutritracker/features/auth/login_screen.dart';
import 'package:opennutritracker/features/auth/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:opennutritracker/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:opennutritracker/services/daily_steps_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggerConfig.intiLogger();
  await initLocator();
  await _configureDailyStepsBackgroundFetch();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Skip onboarding and use default user values
  const isUserInitialized = true;
  final hasAuthSession = Supabase.instance.client.auth.currentSession != null;
  final configRepo = locator<ConfigRepository>();
  final hasAcceptedAnonymousData =
      await configRepo.getConfigHasAcceptedAnonymousData();
  final savedAppTheme = await configRepo.getConfigAppTheme();
  final log = Logger('main');

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    hasAcceptedAnonymousData,
  );

  log.info(
    'Starting App with Crashlytics ${hasAcceptedAnonymousData ? 'enabled' : 'disabled'} ...',
  );
  runAppWithChangeNotifiers(isUserInitialized, hasAuthSession, savedAppTheme);
}

const _dailyStepsBackgroundTaskId = 'daily_steps_fetch';

Future<void> _configureDailyStepsBackgroundFetch() async {
  final log = Logger('_DailyStepsBackgroundFetch');
  final dailyStepsService = locator<DailyStepsService>();

  try {
    final status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 3,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (taskId) async {
        try {
          await dailyStepsService.fetchAndSyncTodaySteps();
        } catch (error, stackTrace) {
          log.warning('Background fetch task failed', error, stackTrace);
        } finally {
          BackgroundFetch.finish(taskId);
        }
      },
      (taskId) async {
        BackgroundFetch.finish(taskId);
      },
    );

    log.info('BackgroundFetch configured with status $status');

    await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

    await BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: _dailyStepsBackgroundTaskId,
        delay: const Duration(minutes: 3).inMilliseconds,
        periodic: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresBatteryNotLow: false,
        requiresStorageNotLow: false,
      ),
    );
  } catch (error, stackTrace) {
    log.warning('Failed to configure BackgroundFetch', error, stackTrace);
  }
}

@pragma('vm:entry-point')
Future<void> backgroundFetchHeadlessTask(HeadlessTask task) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }

  final log = Logger('DailyStepsHeadlessTask');

  try {
    if (!locator.isRegistered<DailyStepsService>()) {
      await initLocator();
    }

    final service = locator<DailyStepsService>();
    await service.fetchAndSyncTodaySteps();
  } catch (error, stackTrace) {
    log.warning('Headless background fetch failed', error, stackTrace);
  } finally {
    BackgroundFetch.finish(task.taskId);
  }
}

void runAppWithChangeNotifiers(
  bool userInitialized,
  bool hasAuthSession,
  AppThemeEntity savedAppTheme,
) =>
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeModeProvider(appTheme: savedAppTheme),
        child: AtlasTrackerApp(
          userInitialized: userInitialized,
          hasAuthSession: hasAuthSession,
        ),
      ),
    );

class AtlasTrackerApp extends StatefulWidget {
  final bool userInitialized;
  final bool hasAuthSession;

  const AtlasTrackerApp({
    super.key,
    required this.userInitialized,
    required this.hasAuthSession,
  });

  @override
  State<AtlasTrackerApp> createState() => _AtlasTrackerAppState();
}

class _AtlasTrackerAppState extends State<AtlasTrackerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: appTextTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: appTextTheme,
      ),
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: widget.hasAuthSession
          ? NavigationOptions.mainRoute
          : NavigationOptions.loginRoute,
      routes: {
        NavigationOptions.mainRoute: (context) => const MainScreen(),
        NavigationOptions.settingsRoute: (context) => const SettingsScreen(),
        NavigationOptions.addMealRoute: (context) => const AddMealScreen(),
        NavigationOptions.scannerRoute: (context) => const ScannerScreen(),
        NavigationOptions.mealDetailRoute: (context) =>
            const MealDetailScreen(),
        NavigationOptions.editMealRoute: (context) => const EditMealScreen(),
        // TEMP: disabled route for adding activities
        // NavigationOptions.addActivityRoute: (context) =>
        //     const AddActivityScreen(),
        NavigationOptions.addWeightRoute: (context) => const AddWeightScreen(),
        // TEMP: disabled route for activity details
        // NavigationOptions.activityDetailRoute: (context) =>
        //     const ActivityDetailScreen(),
        NavigationOptions.imageFullScreenRoute: (context) =>
            const ImageFullScreen(),
        NavigationOptions.createMealRoute: (context) =>
            const MealCreationScreen(),
        NavigationOptions.recipeRoute: (context) => const RecipePage(),
        NavigationOptions.loginRoute: (context) => const LoginScreen(),
        NavigationOptions.resetPasswordRoute: (context) =>
            ResetPasswordScreen(),
      },
    );
  }
}
