import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_role_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'dart:typed_data';

/// Imports user data from a zip stored on Supabase storage.
/// Existing entries are replaced if the incoming entry has a more recent
/// `updatedAt` field.
class ImportDataSupabaseUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;
  final SupabaseClient _client;
  final _log = Logger('ImportDataSupabaseUsecase');

  ImportDataSupabaseUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._userWeightRepository,
    this._recipeRepository,
    this._userRepository,
    this._client,
  );

  Future<bool> importData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String userWeightJsonFileName,
    String recipesJsonFileName,
    String userJsonFileName,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _log.warning('No Supabase session – aborting import');
        return false;
      }

      final bucket = _client.storage.from('exports');
      final files = await bucket.list(path: userId);
      final file = files.firstWhereOrNull((f) => f.name == exportZipFileName);

      if (file == null) {
        _log.fine('No export archive found – first login, skipping import');
        return true; // 👍 Rien à synchroniser
      }

      final filePath = '$userId/$exportZipFileName';
      final Uint8List data = await bucket.download(filePath);
      final archive = ZipDecoder().decodeBytes(data);

      // Verify archive integrity here
      final userActivityFile = archive.findFile(userActivityJsonFileName);
      final intakeFile = archive.findFile(userIntakeJsonFileName);
      final trackedDayFile = archive.findFile(trackedDayJsonFileName);
      final userWeightFile = archive.findFile(userWeightJsonFileName);
      final recipesFile = archive.findFile(recipesJsonFileName);
      final userFile = archive.findFile(userJsonFileName);

      if ([
        userActivityFile,
        intakeFile,
        trackedDayFile,
        userWeightFile,
        recipesFile,
        userFile
      ].any((f) => f == null)) {
        throw Exception('Archive is missing required files');
      }

      Future<String?> restoreImage(String? path) async {
        if (path == null || path.startsWith('http')) return path;
        final fileName = p.basename(path);
        final imageFile = archive.findFile('images/$fileName');
        if (imageFile == null) return null;
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(imageFile.content as List<int>);
        return fileName;
      }

      Future<MealDBO> convertMeal(MealDBO meal) async {
        return MealDBO(
          code: meal.code,
          name: meal.name,
          brands: meal.brands,
          thumbnailImageUrl: await restoreImage(meal.thumbnailImageUrl),
          mainImageUrl: await restoreImage(meal.mainImageUrl),
          url: await restoreImage(meal.url),
          mealQuantity: meal.mealQuantity,
          mealUnit: meal.mealUnit,
          servingQuantity: meal.servingQuantity,
          servingUnit: meal.servingUnit,
          servingSize: meal.servingSize,
          nutriments: meal.nutriments,
          source: meal.source,
        );
      }

      // ----- USER -----
      final userJsonString = utf8.decode(userFile!.content as List<int>);
      final userMap = jsonDecode(userJsonString) as Map<String, dynamic>;
      final userDBO = UserDBO(
        name: userMap['name'] as String,
        birthday: DateTime.parse(userMap['birthday'] as String),
        heightCM: (userMap['heightCM'] as num).toDouble(),
        weightKG: (userMap['weightKG'] as num).toDouble(),
        gender: UserGenderDBO.values[userMap['gender'] as int],
        goal: UserWeightGoalDBO.values[userMap['goal'] as int],
        pal: UserPALDBO.values[userMap['pal'] as int],
        role: UserRoleDBO.values[userMap['role'] as int],
        profileImagePath: userMap['profileImagePath'] as String?,
      );
      userDBO.profileImagePath = await restoreImage(userDBO.profileImagePath);
      await _userRepository.updateUserData(UserEntity.fromUserDBO(userDBO));

      // ----- RECIPES -----
      final recipesJsonString = utf8.decode(recipesFile!.content as List<int>);
      final recipesList =
          (jsonDecode(recipesJsonString) as List).cast<Map<String, dynamic>>();
      final recipesDBOs =
          recipesList.map((e) => RecipesDBO.fromJson(e)).toList();

      final List<RecipesDBO> updatedRecipes = [];
      for (final r in recipesDBOs) {
        final updatedMeal = await convertMeal(r.recipe);
        final updatedIngredients = <IntakeForRecipeDBO>[];
        for (final ing in r.ingredients) {
          final m = ing.meal;
          final updatedM = m == null ? null : await convertMeal(m);
          updatedIngredients.add(IntakeForRecipeDBO(
            code: ing.code,
            name: ing.name,
            unit: ing.unit,
            amount: ing.amount,
            meal: updatedM,
          ));
        }
        updatedRecipes.add(RecipesDBO(
          recipe: updatedMeal,
          ingredients: updatedIngredients,
        ));
      }
      if (updatedRecipes.isNotEmpty) {
        await _recipeRepository.addAllRecipeDBOs(updatedRecipes);
      }

      // ----- INTAKES -----
      final intakeJsonString = utf8.decode(intakeFile!.content as List<int>);
      final intakeList =
          (jsonDecode(intakeJsonString) as List).cast<Map<String, dynamic>>();
      final intakeDBOs = intakeList.map((e) => IntakeDBO.fromJson(e)).toList();

      final existingIntakes = await _intakeRepository.getAllIntakesDBO();
      final intakeMap = {for (final i in existingIntakes) i.id: i};
      final intakeIds = intakeDBOs.map((e) => e.id).toSet();
      for (final existing in existingIntakes) {
        if (!intakeIds.contains(existing.id)) {
          await _intakeRepository
              .deleteIntake(IntakeEntity.fromIntakeDBO(existing));
        }
      }
      for (final dbo in intakeDBOs) {
        final current = intakeMap[dbo.id];
        if (current == null) {
          await _intakeRepository.addAllIntakeDBOs([dbo]);
        } else if (dbo.updatedAt.isAfter(current.updatedAt)) {
          await _intakeRepository
              .deleteIntake(IntakeEntity.fromIntakeDBO(current));
          await _intakeRepository.addAllIntakeDBOs([dbo]);
        }
      }

      // ----- TRACKED DAYS -----
      final trackedDayJsonString =
          utf8.decode(trackedDayFile!.content as List<int>);
      final trackedDayList = (jsonDecode(trackedDayJsonString) as List)
          .cast<Map<String, dynamic>>();
      final trackedDayDBOs =
          trackedDayList.map((e) => TrackedDayDBO.fromJson(e)).toList();

      final existingDays = await _trackedDayRepository.getAllTrackedDaysDBO();
      final dayMap = {for (final d in existingDays) d.day.toIso8601String(): d};
      final dayKeys =
          trackedDayDBOs.map((e) => e.day.toIso8601String()).toSet();
      for (final existing in existingDays) {
        final key = existing.day.toIso8601String();
        if (!dayKeys.contains(key)) {
          await _trackedDayRepository.deleteTrackedDay(existing.day);
        }
      }
      final List<TrackedDayDBO> daysToSave = [];
      for (final dbo in trackedDayDBOs) {
        final key = dbo.day.toIso8601String();
        final current = dayMap[key];
        if (current == null || dbo.updatedAt.isAfter(current.updatedAt)) {
          daysToSave.add(dbo);
        }
      }
      if (daysToSave.isNotEmpty) {
        await _trackedDayRepository.addAllTrackedDays(daysToSave);
      }

      // ----- USER WEIGHT -----
      final userWeightJsonString =
          utf8.decode(userWeightFile!.content as List<int>);
      final userWeightList = (jsonDecode(userWeightJsonString) as List)
          .cast<Map<String, dynamic>>();
      final userWeightDBOs =
          userWeightList.map((e) => UserWeightDbo.fromJson(e)).toList();

      final existingWeights =
          await _userWeightRepository.getAllUserWeightDBOs();
      final weightMap = {
        for (final w in existingWeights)
          DateTime(w.date.year, w.date.month, w.date.day).toIso8601String(): w
      };
      final weightKeys = userWeightDBOs
          .map((e) =>
              DateTime(e.date.year, e.date.month, e.date.day).toIso8601String())
          .toSet();
      for (final existing in existingWeights) {
        final key =
            DateTime(existing.date.year, existing.date.month, existing.date.day)
                .toIso8601String();
        if (!weightKeys.contains(key)) {
          await _userWeightRepository.deleteUserWeightByDate(existing.date);
        }
      }
      for (final dbo in userWeightDBOs) {
        final key = DateTime(dbo.date.year, dbo.date.month, dbo.date.day)
            .toIso8601String();
        final current = weightMap[key];
        if (current == null) {
          await _userWeightRepository.addAllUserWeightDBOs([dbo]);
        } else if (dbo.updatedat.isAfter(current.updatedat)) {
          await _userWeightRepository.deleteUserWeightByDate(current.date);
          await _userWeightRepository.addAllUserWeightDBOs([dbo]);
        }
      }

      return true;
    } catch (e, stack) {
      _log.severe('Failed to import from Supabase', e, stack);
      return false;
    }
  }
}
