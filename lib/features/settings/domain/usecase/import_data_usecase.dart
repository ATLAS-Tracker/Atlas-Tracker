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

class ImportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;

  ImportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository, this._userWeightRepository);

  /// Imports user activity, intake, and tracked day data from a zip file
  /// containing JSON files.
  ///
  /// Returns true if import was successful, false otherwise.
  Future<bool> importData(String userActivityJsonFileName,
      String userIntakeJsonFileName,
      String trackedDayJsonFileName,
      String userWeightJsonFileName) async {
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
    if (userWeightFile != null) {
      final userWeightJsonString =
          utf8.decode(userWeightFile.content as List<int>);
      final userWeightList = (jsonDecode(userWeightJsonString) as List)
          .cast<Map<String, dynamic>>();

      final userWeightDBOs =
          userWeightList.map((json) => UserWeightDbo.fromJson(json)).toList();

      await _userWeightRepository.addAllUserWeightDBOs(userWeightDBOs);
    } else {
      throw Exception('User weight file not found in the archive');
    }

    return true;
  }
}
