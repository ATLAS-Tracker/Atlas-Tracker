import 'package:opennutritracker/core/data/tracked_day_totals.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/common_config_dbo.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_role_dbo.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';

class HiveDBProvider extends ChangeNotifier {
  HiveDBProvider({String? userId}) : _userId = userId;
  static final Logger _log = Logger('HiveDBProvider');
  static const configBoxName = 'ConfigBox';
  static const commonConfigBoxName = 'commonConfigBox';
  static const intakeBoxName = 'IntakeBox';
  static const userActivityBoxName = 'UserActivityBox';
  static const userBoxName = 'UserBox';
  static const trackedDayBoxName = 'TrackedDayBox';
  static const recipeBoxName = "RecipeBox";
  static const userWeightBoxName = 'UserWeightBox';
  static const macroGoalBoxName = 'MacroGoalBox';
  static const dailyStepsBoxName = 'DailyStepsBox';
  static const stepsDateBoxName = 'steps_date';
  static const stepsDateEntryKey = 'steps_date';
  static const syncMetadataBoxName = 'SyncMetadataBox';

  String? _userId;
  String? get activeUserId => _userId;
  String _boxName(String base) => _userId == null ? base : '${_userId}_$base';

  late Box<ConfigDBO> configBox;
  late Box<CommonConfigDBO> commonConfigBox;
  late Box<IntakeDBO> intakeBox;
  late Box<UserActivityDBO> userActivityBox;
  late Box<UserDBO> userBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<RecipesDBO> recipeBox;
  late Box<UserWeightDbo> userWeightBox;
  late Box<MacroGoalDbo> macroGoalBox;
  late Box<int> dailyStepsBox;
  late Box<StepsDateDbo> stepsDateBox;
  Box<String>? syncMetadataBox;

  List<StreamSubscription<BoxEvent>>? _updateSubs;

  static bool _adaptersRegistered = false;

  // Registers Hive type adapters
  static void _registerAdapters() {
    if (_adaptersRegistered) return;
    _log.finer('📦 Registering Hive adapters (one-time)');
    Hive.registerAdapter(ConfigDBOAdapter());
    Hive.registerAdapter(CommonConfigDBOAdapter());
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(MealDBOAdapter());
    Hive.registerAdapter(IntakeForRecipeDBOAdapter());
    Hive.registerAdapter(MealOrRecipeDBOAdapter());
    Hive.registerAdapter(MealNutrimentsDBOAdapter());
    Hive.registerAdapter(MealSourceDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
    Hive.registerAdapter(RecipesDBOAdapter());
    Hive.registerAdapter(UserDBOAdapter());
    Hive.registerAdapter(UserGenderDBOAdapter());
    Hive.registerAdapter(UserWeightGoalDBOAdapter());
    Hive.registerAdapter(UserPALDBOAdapter());
    Hive.registerAdapter(UserRoleDBOAdapter());
    Hive.registerAdapter(TrackedDayDBOAdapter());
    Hive.registerAdapter(UserActivityDBOAdapter());
    Hive.registerAdapter(PhysicalActivityDBOAdapter());
    Hive.registerAdapter(PhysicalActivityTypeDBOAdapter());
    Hive.registerAdapter(AppThemeDBOAdapter());
    Hive.registerAdapter(UserWeightDboAdapter());
    Hive.registerAdapter(MacroGoalDboAdapter());
    Hive.registerAdapter(StepsDateDboAdapter());
    _adaptersRegistered = true;
  }

  Future<void> initHiveDB(Uint8List encryptionKey, {String? userId}) async {
    try {
      _log.info(
          '↪️  initHiveDB called — currentUserId=$_userId → newUserId=$userId');
      final encryptionCypher = HiveAesCipher(encryptionKey);

      await Hive.initFlutter();

      // Enregistrement des adaptateurs avant toute ouverture de boîte
      _registerAdapters();

      // Close previously opened boxes and watcher if any
      if (Hive.isBoxOpen(_boxName(configBoxName))) {
        _log.fine('🔒 Closing boxes for user=$_userId');
        await stopUpdateWatchers();

        await Future.wait([
          configBox.close(),
          intakeBox.close(),
          recipeBox.close(),
          if (syncMetadataBox != null) syncMetadataBox!.close(),
          userActivityBox.close(),
          userBox.close(),
          trackedDayBox.close(),
          userWeightBox.close(),
          macroGoalBox.close(),
          dailyStepsBox.close(),
          stepsDateBox.close(),
        ]);
        _log.fine('✅ Boxes closed');
      }

      _userId = userId;
      _log.fine('🆕 _userId set to $_userId');

      if (!Hive.isBoxOpen(commonConfigBoxName)) {
        _log.fine('🚪 Opening common config box…');
        commonConfigBox = await Hive.openBox<CommonConfigDBO>(
            commonConfigBoxName,
            encryptionCipher: encryptionCypher);
        _log.fine('✅ Common config box opened');
      } else {
        commonConfigBox = Hive.box<CommonConfigDBO>(commonConfigBoxName);
      }

      // Helpers pour log la réouverture
      Future<Box<T>> openBox<T>(String baseName) async {
        final name = _boxName(baseName);
        _log.fine('🚪 Opening box $name …');
        final box =
            await Hive.openBox<T>(name, encryptionCipher: encryptionCypher);
        _log.fine('📂 Box $name opened (size=${box.length})');
        return box;
      }

      configBox = await openBox(configBoxName);
      intakeBox = await openBox(intakeBoxName);
      recipeBox = await openBox(recipeBoxName);
      syncMetadataBox = await openBox<String>(syncMetadataBoxName);
      userActivityBox = await openBox(userActivityBoxName);
      userBox = await openBox(userBoxName);
      trackedDayBox = await openBox(trackedDayBoxName);
      macroGoalBox = await openBox(macroGoalBoxName);
      final migrations = await Hive.openBox<bool>(_boxName('MigrationsBox'));
      try {
        await TrackedDayTotals(intakeBox, trackedDayBox, macroGoalBox)
            .migrate(migrations);
      } finally {
        await migrations.close();
      }
      userWeightBox = await openBox(userWeightBoxName);

      dailyStepsBox = await openBox(dailyStepsBoxName);
      stepsDateBox = await openBox(stepsDateBoxName);

      if (!stepsDateBox.containsKey(stepsDateEntryKey)) {
        await stepsDateBox.put(
          stepsDateEntryKey,
          StepsDateDbo(
            lastSteps: 0,
            nowSteps: 0,
            diff: 0,
            lastDate: DateTime.now(),
          ),
        );
      }
      _log.info('✅ Hive initialised for user=$_userId');
    } catch (e, s) {
      _log.severe('Failed to initialize Hive DB', e, s);
      rethrow;
    }
  }

  static generateNewHiveEncryptionKey() => Hive.generateSecureKey();

  void startUpdateWatchers(ConfigDataSource config) {
    stopUpdateWatchers();
    _updateSubs = [
      intakeBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      userActivityBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      trackedDayBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      userWeightBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      macroGoalBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      dailyStepsBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
      stepsDateBox
          .watch()
          .listen((_) => config.setLastDataUpdate(DateTime.now().toUtc())),
    ];
  }

  Future<void> stopUpdateWatchers() async {
    if (_updateSubs != null) {
      for (final sub in _updateSubs!) {
        await sub.cancel();
      }
      _updateSubs = null;
    }
  }

  /// Removes all user-specific data from the opened Hive boxes.
  ///
  /// The common configuration box (e.g., for theme settings) is not cleared,
  /// allowing settings to persist across user sessions.
  Future<void> clearAllData() async {
    _log.info('🗑️ Clearing user Hive boxes');
    await Future.wait([
      configBox.clear(),
      intakeBox.clear(),
      recipeBox.clear(),
      if (syncMetadataBox != null) syncMetadataBox!.clear(),
      userActivityBox.clear(),
      userBox.clear(),
      trackedDayBox.clear(),
      userWeightBox.clear(),
      macroGoalBox.clear(),
      dailyStepsBox.clear(),
      stepsDateBox.clear(),
    ]);
  }

  Future<void> _deleteBox(String baseName) async {
    final name = _boxName(baseName);
    if (await Hive.boxExists(name)) {
      _log.finer('🗑️ Deleting box $name from disk');
      await Hive.deleteBoxFromDisk(name);
    }
  }

  /// Completely removes the Hive database for the currently active user from
  /// disk.
  ///
  /// Only boxes prefixed with the current user's id are removed. All opened
  /// boxes are closed before deletion. After calling this method, all local
  /// data for that user will be permanently deleted.
  Future<void> deleteCurrentUserDatabase() async {
    if (_userId == null) {
      _log.warning('deleteCurrentUserDatabase called with no active user');
      return;
    }

    _log.info('🗑️ Deleting Hive database for user=$_userId');

    if (Hive.isBoxOpen(_boxName(configBoxName))) {
      await stopUpdateWatchers();

      await Future.wait([
        configBox.close(),
        intakeBox.close(),
        recipeBox.close(),
        if (syncMetadataBox != null) syncMetadataBox!.close(),
        userActivityBox.close(),
        userBox.close(),
        trackedDayBox.close(),
        userWeightBox.close(),
        macroGoalBox.close(),
        dailyStepsBox.close(),
        stepsDateBox.close(),
      ]);
    }

    await Future.wait([
      _deleteBox(configBoxName),
      _deleteBox(intakeBoxName),
      _deleteBox(userActivityBoxName),
      _deleteBox(userBoxName),
      _deleteBox(trackedDayBoxName),
      _deleteBox(recipeBoxName),
      _deleteBox(syncMetadataBoxName),
      _deleteBox(userWeightBoxName),
      _deleteBox(macroGoalBoxName),
      _deleteBox(dailyStepsBoxName),
      _deleteBox(stepsDateBoxName),
      _deleteBox('MigrationsBox'),
    ]);

    _log.info('✅ Hive database deleted for user=$_userId');
  }

  Future<void> initForUser(String? userId) async {
    _log.info('🔄 initForUser($userId) called');
    final secure = SecureAppStorageProvider();
    await initHiveDB(await secure.getHiveEncryptionKey(), userId: userId);
  }

  @override
  void dispose() {
    stopUpdateWatchers();
    super.dispose();
  }
}
