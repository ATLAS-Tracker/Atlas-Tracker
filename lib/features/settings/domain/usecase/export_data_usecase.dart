import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;

  ExportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository, this._userWeightRepository);

  /// Exports user activity, intake, and tracked day data to a zip of json
  /// files at a user specified location.
  Future<bool> exportData(
      String exportZipFileName,
      String userActivityJsonFileName,
      String userIntakeJsonFileName,
      String trackedDayJsonFileName,
      String userWeightJsonFileName) async {
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

    // Create a zip file with the exported data
    final archive = Archive();
    archive.addFile(
      ArchiveFile(userActivityJsonFileName, userActivityJsonBytes.length,
          userActivityJsonBytes),
    );
    archive.addFile(
      ArchiveFile(
          userIntakeJsonFileName, intakeJsonBytes.length, intakeJsonBytes),
    );
    archive.addFile(
      ArchiveFile(trackedDayJsonFileName, trackedDayJsonBytes.length,
          trackedDayJsonBytes),
    );
    archive.addFile(
      ArchiveFile(userWeightJsonFileName, userWeightJsonBytes.length,
          userWeightJsonBytes),
    );

    // Save the zip file to the user specified location
    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.platform.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }
}
