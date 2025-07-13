import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
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
import 'package:opennutritracker/features/sync/tracked_day_change_isolate.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:logging/logging.dart';

class HiveDBProvider extends ChangeNotifier {
  static final Logger _log = Logger('HiveDBProvider');
  static const configBoxName = 'ConfigBox';
  static const intakeBoxName = 'IntakeBox';
  static const userActivityBoxName = 'UserActivityBox';
  static const userBoxName = 'UserBox';
  static const trackedDayBoxName = 'TrackedDayBox';
  static const recipeBoxName = "RecipeBox";
  static const userWeightBoxName = 'UserWeightBox';

  String? _userId;
  String _boxName(String base) => _userId == null ? base : '${_userId}_$base';

  late Box<ConfigDBO> configBox;
  late Box<IntakeDBO> intakeBox;
  late Box<UserActivityDBO> userActivityBox;
  late Box<UserDBO> userBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<RecipesDBO> recipeBox;
  late TrackedDayChangeIsolate trackedDayWatcher;
  late Box<UserWeightDbo> userWeightBox;

  List<StreamSubscription<BoxEvent>>? _updateSubs;

  static bool _adaptersRegistered = false;

  Future<void> initHiveDB(Uint8List encryptionKey, {String? userId}) async {
    try {
      _log.info(
          '↪️  initHiveDB called — currentUserId=$_userId → newUserId=$userId');
      final encryptionCypher = HiveAesCipher(encryptionKey);

      // Close previously opened boxes and watcher if any
      if (Hive.isBoxOpen(_boxName(configBoxName))) {
        // trackedDayWatcher must be stopped before its box is closed
        _log.fine('🔒 Closing boxes for user=$_userId');
        await trackedDayWatcher.stop();
        await stopUpdateWatchers();

        // To prevent resource leaks, any new box added to this provider must also be added here.
        await Future.wait([
          configBox.close(),
          intakeBox.close(),
          recipeBox.close(),
          userActivityBox.close(),
          userBox.close(),
          trackedDayBox.close(),
          userWeightBox.close(),
        ]);
        _log.fine('✅ Boxes closed');
      }

      _userId = userId;
      _log.fine('🆕 _userId set to $_userId');

      await Hive.initFlutter();
      if (!_adaptersRegistered) {
        _log.finer('📦 Registering Hive adapters (one-time)');
        Hive.registerAdapter(ConfigDBOAdapter());
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
        _adaptersRegistered = true;
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
      userActivityBox = await openBox(userActivityBoxName);
      userBox = await openBox(userBoxName);
      trackedDayBox = await openBox(trackedDayBoxName);
      trackedDayWatcher = TrackedDayChangeIsolate(trackedDayBox);
      await trackedDayWatcher.start();
      userWeightBox = await openBox(userWeightBoxName);
      _log.info('✅ Hive initialised for user=$_userId');
    } catch (e, s) {
      // Log the error for debugging. You'll need to add a logger to the class.
      _log.severe('Failed to initialize Hive DB', e, s);
      // Re-throw or handle the error as appropriate for your app's architecture.
      rethrow;
    }
  }

  static generateNewHiveEncryptionKey() => Hive.generateSecureKey();

  void startUpdateWatchers(ConfigDataSource config) {
    stopUpdateWatchers();
    _updateSubs = [
      intakeBox.watch().listen((_) =>
          config.setLastDataUpdate(DateTime.now().toUtc())),
      userActivityBox.watch().listen((_) =>
          config.setLastDataUpdate(DateTime.now().toUtc())),
      trackedDayBox.watch().listen((_) =>
          config.setLastDataUpdate(DateTime.now().toUtc())),
      userWeightBox.watch().listen((_) =>
          config.setLastDataUpdate(DateTime.now().toUtc())),
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

  /// Removes all user data from the opened Hive boxes.
  ///
  /// The configuration box is intentionally **not** cleared so that user
  /// preferences such as theme and units persist across logins.
  Future<void> clearAllData() async {
    _log.info('🗑️ Clearing user Hive boxes');
    await Future.wait([
      intakeBox.clear(),
      recipeBox.clear(),
      userActivityBox.clear(),
      userBox.clear(),
      trackedDayBox.clear(),
      userWeightBox.clear(),
    ]);
  }

  /// Helper to (re)initialize Hive for the provided [userId].
  /// This fetches the encryption key from secure storage and delegates
  /// to [initHiveDB].
  Future<void> initForUser(String? userId) async {
    _log.info('🔄 initForUser($userId) called');
    final secure = SecureAppStorageProvider();
    await initHiveDB(await secure.getHiveEncryptionKey(), userId: userId);
  }

  @override
  void dispose() {
    trackedDayWatcher.stop();
    stopUpdateWatchers();
    super.dispose();
  }
}
