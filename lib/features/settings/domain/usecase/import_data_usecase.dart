import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_role_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class ImportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  ImportDataUsecase(
      this._userActivityRepository,
      this._intakeRepository,
      this._trackedDayRepository,
      this._userWeightRepository,
      this._recipeRepository,
      this._userRepository);

  /// Imports user activity, intake, and tracked day data from a zip file
  /// containing JSON files.
  ///
  /// Returns true if import was successful, false otherwise.
  Future<bool> importData(
      String userActivityJsonFileName,
      String userIntakeJsonFileName,
      String trackedDayJsonFileName,
      String userWeightJsonFileName,
      String recipesJsonFileName,
      String userJsonFileName) async {
    // Allow user to pick a zip file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('No file selected');
    }

    // Read the file bytes using the file path
    final file = File(result.files.single.path!);
    final zipBytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Extract and process user activity data
    final userActivityFile = archive.findFile(userActivityJsonFileName);
    if (userActivityFile != null) {
      final userActivityJsonString =
          utf8.decode(userActivityFile.content as List<int>);
      final userActivityList = (jsonDecode(userActivityJsonString) as List)
          .cast<Map<String, dynamic>>();

      final userActivityDBOs = userActivityList
          .map((json) => UserActivityDBO.fromJson(json))
          .toList();

      await _userActivityRepository.addAllUserActivityDBOs(userActivityDBOs);
    } else {
      throw Exception('User activity file not found in the archive');
    }

    // Extract and process intake data
    final intakeFile = archive.findFile(userIntakeJsonFileName);
    if (intakeFile != null) {
      final intakeJsonString = utf8.decode(intakeFile.content as List<int>);
      final intakeList =
          (jsonDecode(intakeJsonString) as List).cast<Map<String, dynamic>>();

      final intakeDBOs =
          intakeList.map((json) => IntakeDBO.fromJson(json)).toList();

      await _intakeRepository.addAllIntakeDBOs(intakeDBOs);
    } else {
      throw Exception('Intake file not found in the archive');
    }

    // Extract and process tracked day data
    final trackedDayFile = archive.findFile(trackedDayJsonFileName);
    if (trackedDayFile != null) {
      final trackedDayJsonString =
          utf8.decode(trackedDayFile.content as List<int>);
      final trackedDayList = (jsonDecode(trackedDayJsonString) as List)
          .cast<Map<String, dynamic>>();

      final trackedDayDBOs =
          trackedDayList.map((json) => TrackedDayDBO.fromJson(json)).toList();

      await _trackedDayRepository.addAllTrackedDays(trackedDayDBOs);
    } else {
      throw Exception('Tracked day file not found in the archive');
    }

    // Extract and process user weight data
    final userWeightFile = archive.findFile(userWeightJsonFileName);
    final recipesFile = archive.findFile(recipesJsonFileName);
    final userFile = archive.findFile(userJsonFileName);
    if (userWeightFile != null && recipesFile != null && userFile != null) {
      final userWeightJsonString =
          utf8.decode(userWeightFile.content as List<int>);
      final userWeightList = (jsonDecode(userWeightJsonString) as List)
          .cast<Map<String, dynamic>>();

      final userWeightDBOs =
          userWeightList.map((json) => UserWeightDbo.fromJson(json)).toList();

      await _userWeightRepository.addAllUserWeightDBOs(userWeightDBOs);

      final userJsonString = utf8.decode(userFile.content as List<int>);
      final userMap = jsonDecode(userJsonString) as Map<String, dynamic>;
      final dir = await getApplicationDocumentsDirectory();
      String? profilePath;
      if (userMap['profileImagePath'] != null) {
        final imageName = userMap['profileImagePath'] as String;
        final imageEntry = archive.findFile('images/$imageName');
        if (imageEntry != null) {
          final file = File(p.join(dir.path, imageName));
          await file.writeAsBytes(imageEntry.content as List<int>);
          profilePath = imageName;
        }
      }
      final userDBO = UserDBO(
        name: userMap['name'] as String,
        birthday: DateTime.parse(userMap['birthday'] as String),
        heightCM: (userMap['heightCM'] as num).toDouble(),
        weightKG: (userMap['weightKG'] as num).toDouble(),
        gender: UserGenderDBO.values[userMap['gender'] as int],
        goal: UserWeightGoalDBO.values[userMap['goal'] as int],
        pal: UserPALDBO.values[userMap['pal'] as int],
        role: UserRoleDBO.values[userMap['role'] as int],
        profileImagePath: profilePath,
      );
      await _userRepository.updateUserData(UserEntity.fromUserDBO(userDBO));

      final recipesJsonString = utf8.decode(recipesFile.content as List<int>);
      final recipesList =
          (jsonDecode(recipesJsonString) as List).cast<Map<String, dynamic>>();
      final recipesDBOs =
          recipesList.map((e) => RecipesDBO.fromJson(e)).toList();

      Future<MealDBO> convMeal(MealDBO meal) async {
        String? copyPath(String? path) {
          if (path == null || path.startsWith('http')) return null;
          return p.basename(path);
        }

        String? stored(String? pName) {
          if (pName == null) return null;
          final entry = archive.findFile('images/$pName');
          if (entry == null) return null;
          final file = File(p.join(dir.path, pName));
          file.writeAsBytesSync(entry.content as List<int>);
          return pName;
        }

        final thumb = stored(copyPath(meal.thumbnailImageUrl));
        final main = stored(copyPath(meal.mainImageUrl));
        final url = stored(copyPath(meal.url));
        return MealDBO(
          code: meal.code,
          name: meal.name,
          brands: meal.brands,
          thumbnailImageUrl: thumb,
          mainImageUrl: main,
          url: url,
          mealQuantity: meal.mealQuantity,
          mealUnit: meal.mealUnit,
          servingQuantity: meal.servingQuantity,
          servingUnit: meal.servingUnit,
          servingSize: meal.servingSize,
          nutriments: meal.nutriments,
          source: meal.source,
        );
      }

      final List<RecipesDBO> updatedRecipes = [];
      for (final r in recipesDBOs) {
        final meal = await convMeal(r.recipe);
        final updatedIngredients = <IntakeForRecipeDBO>[];
        for (final ing in r.ingredients) {
          final m = ing.meal;
          final newMeal = m == null ? null : await convMeal(m);
          updatedIngredients.add(IntakeForRecipeDBO(
            code: ing.code,
            name: ing.name,
            unit: ing.unit,
            amount: ing.amount,
            meal: newMeal,
          ));
        }
        updatedRecipes.add(RecipesDBO(
            recipe: meal,
            ingredients: updatedIngredients,
            portions: r.portions));
      }
      if (updatedRecipes.isNotEmpty) {
        await _recipeRepository.addAllRecipeDBOs(updatedRecipes);
      }
    } else {
      throw Exception('User weight file not found in the archive');
    }

    return true;
  }
}
