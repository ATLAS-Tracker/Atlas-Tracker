import 'dart:io' show Platform;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_data_source.dart';
import 'package:opennutritracker/core/data/repository/macro_goal_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/ont_image_cache_manager.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/recent_activities_bloc.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_supabase_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_supabase_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/services/daily_steps_sync_service.dart';
import 'package:opennutritracker/services/step_count/android_step_count_provider.dart';
import 'package:opennutritracker/services/step_count/step_count_provider.dart';
import 'package:opennutritracker/services/step_count_service.dart';
import 'package:opennutritracker/services/step_tracking/android_step_tracking_controller.dart';
import 'package:opennutritracker/services/step_tracking/apple_step_tracking_controller.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller_factory.dart';

final locator = GetIt.instance;
const _userScope = 'user_scope';

Future<void> initLocator() async {
  // Backend
  locator.registerLazySingleton<Connectivity>(() => Connectivity());
  await Supabase.initialize(
    url: Env.supabaseProjectUrl,
    anonKey: Env.supabaseProjectAnonKey,
  );

  locator.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Init secure storage and Hive database;
  final hiveDBProvider = HiveDBProvider();
  await hiveDBProvider.initForUser(
    Supabase.instance.client.auth.currentUser?.id,
  );

  locator.registerSingleton<HiveDBProvider>(hiveDBProvider);

  // Cache manager
  locator.registerLazySingleton<CacheManager>(
    () => OntImageCacheManager.instance,
  );

  await registerUserScope(hiveDBProvider);
}

Future<void> registerUserScope(HiveDBProvider hive) async {
// --- si un user-scope est déjà présent, on le détruit ---
  if (locator.currentScopeName == _userScope) {
    await locator.popScope(); // ferme les anciens singletons + dispose()
  }

// --- nouveau scope isolé pour l’utilisateur courant ---
  locator.pushNewScope(
    scopeName: _userScope, // nom pour le retrouver la prochaine fois
  );

  // DataSources
  final configDS = ConfigDataSource(hive);
  locator.registerLazySingleton(() => configDS);
  hive.startUpdateWatchers(configDS);
  locator.registerLazySingleton<UserDataSource>(() => UserDataSource(
      hive, Supabase.instance.client.auth.currentUser?.id ?? 'default_user'));
  locator.registerLazySingleton(() => IntakeDataSource(hive));
  locator.registerLazySingleton(() => RecipesDataSource(hive));
  locator.registerLazySingleton(() => UserActivityDataSource(hive));
  locator.registerLazySingleton(() => PhysicalActivityDataSource());
  locator.registerLazySingleton(() => TrackedDayDataSource(hive));
  locator.registerLazySingleton(() => UserWeightDataSource(hive));
  locator.registerLazySingleton(() => MacroGoalDataSource(hive));
  locator.registerLazySingleton<OFFDataSource>(() => OFFDataSource());
  locator.registerLazySingleton<FDCDataSource>(() => FDCDataSource());
  locator.registerLazySingleton<SpFdcDataSource>(() => SpFdcDataSource());

  // Repositories
  locator.registerLazySingleton(() => ConfigRepository(locator()));
  locator.registerLazySingleton<UserRepository>(
    () => UserRepository(locator()),
  );
  locator.registerLazySingleton(() => IntakeRepository(locator()));
  locator.registerLazySingleton(() => RecipeRepository(locator()));
  locator.registerLazySingleton(
    () => ProductsRepository(locator(), locator(), locator()),
  );
  locator.registerLazySingleton(() => UserActivityRepository(locator()));
  locator.registerLazySingleton(() => PhysicalActivityRepository(locator()));
  locator.registerLazySingleton(() => TrackedDayRepository(locator()));
  locator.registerLazySingleton(() => UserWeightRepository(locator()));
  locator.registerLazySingleton(() => MacroGoalRepository(locator()));

  // UseCases
  locator.registerLazySingleton<GetConfigUsecase>(
    () => GetConfigUsecase(locator()),
  );
  locator.registerLazySingleton<AddConfigUsecase>(
    () => AddConfigUsecase(locator()),
  );
  locator.registerLazySingleton<GetUserUsecase>(
    () => GetUserUsecase(locator()),
  );
  locator.registerLazySingleton<AddUserUsecase>(
    () => AddUserUsecase(locator()),
  );
  locator.registerLazySingleton<SearchProductsUseCase>(
    () => SearchProductsUseCase(locator()),
  );
  locator.registerLazySingleton<SearchProductByBarcodeUseCase>(
    () => SearchProductByBarcodeUseCase(locator()),
  );
  locator.registerLazySingleton<GetIntakeUsecase>(
    () => GetIntakeUsecase(locator()),
  );
  locator.registerLazySingleton<AddIntakeUsecase>(
    () => AddIntakeUsecase(locator()),
  );
  locator.registerLazySingleton<DeleteIntakeUsecase>(
    () => DeleteIntakeUsecase(locator()),
  );
  locator.registerLazySingleton<DeleteRecipeUsecase>(
    () => DeleteRecipeUsecase(locator()),
  );
  locator.registerLazySingleton<UpdateIntakeUsecase>(
    () => UpdateIntakeUsecase(locator()),
  );
  locator.registerLazySingleton<AddRecipeUsecase>(
    () => AddRecipeUsecase(locator()),
  );
  locator.registerLazySingleton<GetRecipeUsecase>(
    () => GetRecipeUsecase(locator()),
  );
  locator.registerLazySingleton<GetUserActivityUsecase>(
    () => GetUserActivityUsecase(locator()),
  );
  locator.registerLazySingleton<AddUserActivityUsecase>(
    () => AddUserActivityUsecase(locator()),
  );
  locator.registerLazySingleton<DeleteUserActivityUsecase>(
    () => DeleteUserActivityUsecase(locator()),
  );
  locator.registerLazySingleton<GetPhysicalActivityUsecase>(
    () => GetPhysicalActivityUsecase(locator()),
  );
  locator.registerLazySingleton<GetTrackedDayUsecase>(
    () => GetTrackedDayUsecase(locator()),
  );
  locator.registerLazySingleton<AddTrackedDayUsecase>(
    () => AddTrackedDayUsecase(locator()),
  );
  locator.registerLazySingleton(
    () => GetKcalGoalUsecase(),
  );
  locator.registerLazySingleton(() => GetMacroGoalUsecase());
  locator.registerLazySingleton(
    () => ExportDataUsecase(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton(
    () => ImportDataUsecase(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton(
    () => ExportDataSupabaseUsecase(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton(
    () => ImportDataSupabaseUsecase(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );

  locator.registerLazySingleton<AddWeightUsecase>(
    () => AddWeightUsecase(locator()),
  );
  locator.registerLazySingleton<AddMacroGoalUsecase>(
    () => AddMacroGoalUsecase(),
  );
  locator.registerLazySingleton<GetWeightUsecase>(() => GetWeightUsecase());
  locator.registerLazySingleton<DeleteUserWeightUsecase>(
    () => DeleteUserWeightUsecase(locator()),
  );

  // BLoCs
  locator.registerLazySingleton<HomeBloc>(
    () => HomeBloc(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton(() => DiaryBloc(locator(), locator()));
  locator.registerLazySingleton(
    () => CalendarDayBloc(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(locator(), locator(), locator(), locator(), locator()),
  );
  locator.registerLazySingleton(
    () => SettingsBloc(locator(), locator(), locator(), locator(), locator()),
  );
  locator.registerFactory(
    () => ExportImportBloc(
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerLazySingleton<CreateMealBloc>(
    () => CreateMealBloc(locator()),
  );

  locator.registerFactory<ActivitiesBloc>(() => ActivitiesBloc(locator()));
  locator.registerFactory<RecentActivitiesBloc>(
    () => RecentActivitiesBloc(locator()),
  );
  locator.registerFactory<ActivityDetailBloc>(
    () => ActivityDetailBloc(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerFactory<MealDetailBloc>(
    () => MealDetailBloc(locator(), locator(), locator(), locator()),
  );
  locator.registerFactory<ScannerBloc>(() => ScannerBloc(locator(), locator()));
  locator.registerFactory<EditMealBloc>(() => EditMealBloc(locator()));
  locator.registerFactory<AddMealBloc>(() => AddMealBloc(locator()));
  locator.registerFactory<ProductsBloc>(
    () => ProductsBloc(locator(), locator()),
  );
  locator.registerFactory<FoodBloc>(() => FoodBloc(locator(), locator()));
  locator.registerFactory(() => RecentMealBloc(locator(), locator()));
  locator.registerFactory(
    () => RecipeSearchBloc(locator(), locator(), locator()),
  );
  locator.registerLazySingleton(() => WeightBloc());
  locator.registerLazySingleton(
    () => StepCountService(_createStepCountProvider()),
  );
  locator.registerLazySingleton<StepTrackingControllerFactory>(
    () => PlatformStepTrackingControllerFactory(
      androidBuilder: () => _createAndroidStepTrackingController(locator),
      appleBuilder: _createAppleStepTrackingController,
    ),
  );

  final stepsSyncService = DailyStepsSyncService();
  await stepsSyncService.init();
  locator.registerSingleton<DailyStepsSyncService>(
    stepsSyncService,
    dispose: (s) => s.dispose(),
  );

  await _initializeConfig(locator());
}

StepCountProvider? _createStepCountProvider() {
  try {
    if (Platform.isAndroid) {
      return AndroidStepCountProvider();
    }
  } catch (_) {
    // Platform may throw if not supported (e.g. tests). Assume no provider.
  }
  return null;
}

StepTrackingController? _createAndroidStepTrackingController(GetIt locator) {
  final hiveProvider = locator<HiveDBProvider>();
  final stepsBox =
      hiveProvider.stepsDateBox.get(HiveDBProvider.stepsDateEntryKey);
  if (stepsBox == null) {
    return null;
  }
  return AndroidStepTrackingController(
    stepCountService: locator<StepCountService>(),
    stepsBox: stepsBox,
    dailyStepsSyncService: locator<DailyStepsSyncService>(),
  );
}

StepTrackingController? _createAppleStepTrackingController() {
  return AppleStepTrackingController();
}

Future<void> _initializeConfig(ConfigDataSource configDataSource) async {
  if (!await configDataSource.configInitialized()) {
    configDataSource.initializeConfig();
  }

  if (!await configDataSource.commonConfigInitialized()) {
    configDataSource.initializeCommonConfig();
  }
}
