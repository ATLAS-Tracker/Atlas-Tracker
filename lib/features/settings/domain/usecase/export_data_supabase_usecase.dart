import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';

/// Exports user data to a zip file and uploads it to Supabase storage.
class ExportDataSupabaseUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;
  final SupabaseClient _client;
  final _log = Logger('ExportServiceZipSupabaseUsecase');

  ExportDataSupabaseUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._userWeightRepository,
    this._recipeRepository,
    this._userRepository,
    this._client,
  );

  /// Creates a zipped backup and uploads it to Supabase storage.
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String userWeightJsonFileName,
    String recipesJsonFileName,
    String userJsonFileName,
  ) async {
    // Export user activity data to Json File Bytes
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    final fullUserActivityJson = jsonEncode(
        fullUserActivity.map((activity) => activity.toJson()).toList());
    final userActivityJsonBytes = utf8.encode(fullUserActivityJson);

    // Export intake data to Json File Bytes
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    final fullIntakeJson =
        jsonEncode(fullIntake.map((intake) => intake.toJson()).toList());
    final intakeJsonBytes = utf8.encode(fullIntakeJson);

    // Export tracked day data to Json File Bytes
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    final fullTrackedDayJson = jsonEncode(
        fullTrackedDay.map((trackedDay) => trackedDay.toJson()).toList());
    final trackedDayJsonBytes = utf8.encode(fullTrackedDayJson);

    // Export user weight data to Json File Bytes
    final fullUserWeight = await _userWeightRepository.getAllUserWeightDBOs();
    final fullUserWeightJson =
        jsonEncode(fullUserWeight.map((w) => w.toJson()).toList());
    final userWeightJsonBytes = utf8.encode(fullUserWeightJson);

    // Export recipes data to Json File Bytes
    final fullRecipes = await _recipeRepository.getAllRecipeDBOs();
    final fullRecipesJson =
        jsonEncode(fullRecipes.map((r) => r.toJson()).toList());
    final recipesJsonBytes = utf8.encode(fullRecipesJson);

    if (fullUserActivity.isEmpty &&
        fullIntake.isEmpty &&
        fullTrackedDay.isEmpty &&
        fullUserWeight.isEmpty &&
        fullRecipes.isEmpty) {
      // this handle the case when the user has no hive data because it is the first time,
      // the user attempt to connect to its account but the user is not subscribed

      return true;
    }

    // Export user data to Json File Bytes
    final userDBO = await _userRepository.getUserDBO();
    final userMap = {
      'name': userDBO.name,
      'birthday': userDBO.birthday.toIso8601String(),
      'heightCM': userDBO.heightCM,
      'weightKG': userDBO.weightKG,
      'gender': userDBO.gender.index,
      'goal': userDBO.goal.index,
      'pal': userDBO.pal.index,
      'role': userDBO.role.index,
      'profileImagePath': userDBO.profileImagePath != null
          ? p.basename(userDBO.profileImagePath!)
          : null,
    };
    final userJsonBytes = utf8.encode(jsonEncode(userMap));

    // Create a zip file with the exported data
    final archive = Archive()
      ..addFile(ArchiveFile(userActivityJsonFileName,
          userActivityJsonBytes.length, userActivityJsonBytes))
      ..addFile(ArchiveFile(
          userIntakeJsonFileName, intakeJsonBytes.length, intakeJsonBytes))
      ..addFile(ArchiveFile(trackedDayJsonFileName, trackedDayJsonBytes.length,
          trackedDayJsonBytes))
      ..addFile(ArchiveFile(userWeightJsonFileName, userWeightJsonBytes.length,
          userWeightJsonBytes))
      ..addFile(ArchiveFile(
          recipesJsonFileName, recipesJsonBytes.length, recipesJsonBytes))
      ..addFile(
          ArchiveFile(userJsonFileName, userJsonBytes.length, userJsonBytes));

    final imagePaths = <String>{};
    if (userDBO.profileImagePath != null &&
        !userDBO.profileImagePath!.startsWith('http')) {
      imagePaths.add(userDBO.profileImagePath!);
    }
    for (final recipe in fullRecipes) {
      final paths = [
        recipe.recipe.url,
        recipe.recipe.thumbnailImageUrl,
        recipe.recipe.mainImageUrl,
      ];
      for (final path in paths) {
        if (path != null && path.isNotEmpty && !path.startsWith('http')) {
          imagePaths.add(path);
        }
      }
    }

    for (final path in imagePaths) {
      final file = File(await PathHelper.localImagePath(path));
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final filename = p.basename(path);
        archive.addFile(ArchiveFile('images/$filename', bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);

    final userId = _client.auth.currentUser?.id ?? 'unknown';
    final filePath = '$userId/$exportZipFileName';
    try {
      await _client.storage.from('exports').uploadBinary(
          filePath, Uint8List.fromList(zipBytes),
          fileOptions:
              const FileOptions(contentType: 'application/zip', upsert: true));
      return true;
    } catch (e, stack) {
      _log.severe('Upload FAILED for “$filePath”.', e, stack);
      return false;
    }
  }
}
