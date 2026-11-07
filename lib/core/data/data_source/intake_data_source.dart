import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/tracked_day_totals.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final HiveDBProvider _hive;

  IntakeDataSource(this._hive);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    await addAllIntakes([intakeDBO], localWrite: true);
  }

  Future<void> addAllIntakes(List<IntakeDBO> intakeDBOList,
      {bool localWrite = false}) async {
    log.fine('Adding new intake items to db');
    final metadata = SyncMetadata(_hive.syncMetadataBox);
    final incoming = <String, IntakeDBO>{};
    for (final intake in intakeDBOList) {
      final previous = incoming[intake.id];
      if (previous == null || intake.updatedAt.isAfter(previous.updatedAt)) {
        incoming[intake.id] = intake;
      }
    }
    final updates = <dynamic, IntakeDBO>{};
    final dates = <DateTime>[];
    final duplicates = <dynamic>[];
    final existingById = _hive.intakeBox.values.groupListsBy((row) => row.id);
    for (final intake in incoming.values) {
      final matches = (existingById[intake.id] ?? <IntakeDBO>[])
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final current = matches.firstOrNull;
      final deleted = metadata.deletedAt('user_intakes', intake.id);
      if (localWrite) {
        intake.updatedAt = metadata.nextLocalVersion(
            'user_intakes', intake.id, current?.updatedAt);
      } else if ((deleted != null && !intake.updatedAt.isAfter(deleted)) ||
          (current != null && !intake.updatedAt.isAfter(current.updatedAt))) {
        continue;
      }
      dates.addAll([intake.dateTime, ...matches.map((row) => row.dateTime)]);
      duplicates.addAll(matches.skip(1).map((row) => row.key));
      updates[current?.key ?? intake.id] = intake;
    }
    await _hive.intakeBox.putAll(updates);
    await _hive.intakeBox.deleteAll(duplicates);
    await _recalculate(dates);
  }

  Future<void> deleteIntakeFromId(String intakeId,
      {DateTime? deletedAt}) async {
    log.fine('Deleting intake item from db');
    final deleted =
        _hive.intakeBox.values.where((dbo) => dbo.id == intakeId).toList();
    final dates = deleted.map((intake) => intake.dateTime).toList();
    final versions = deleted.map((row) => row.updatedAt).toList()..sort();
    await SyncMetadata(_hive.syncMetadataBox).markDeleted(
        'user_intakes', intakeId,
        previous: versions.lastOrNull, version: deletedAt);
    await _hive.intakeBox.deleteAll(deleted.map((intake) => intake.key));
    await _recalculate(dates);
  }

  Future<void> _recalculate(Iterable<DateTime> dates) async {
    final affected = dates.toList();
    await SyncMetadata(_hive.syncMetadataBox)
        .markJournalDays(affected.map((day) => day.toDayKey()));
    await TrackedDayTotals(
            _hive.intakeBox, _hive.trackedDayBox, _hive.macroGoalBox)
        .recalculate(affected);
  }

  Future<IntakeDBO?> updateIntake(
      String intakeId, Map<String, dynamic> fields) async {
    log.fine(
        'Updating intake $intakeId with fields ${fields.toString()} in db');
    var intakeObject = _hive.intakeBox.values.indexed
        .where((indexedDbo) => indexedDbo.$2.id == intakeId)
        .firstOrNull;
    if (intakeObject == null) {
      log.fine('Cannot update intake $intakeId as it is non existent');
      return null;
    }
    // Update fields
    final originalDate = intakeObject.$2.dateTime;
    intakeObject.$2.amount = fields['amount'] ?? intakeObject.$2.amount;
    intakeObject.$2.dateTime = fields['dateTime'] ?? intakeObject.$2.dateTime;
    intakeObject.$2.type = fields['type'] ?? intakeObject.$2.type;
    intakeObject.$2.unit = fields['unit'] ?? intakeObject.$2.unit;
    intakeObject.$2.meal = fields['meal'] ?? intakeObject.$2.meal;
    // Always bump updatedAt when mutating an intake
    intakeObject.$2.updatedAt = SyncMetadata(_hive.syncMetadataBox)
        .nextLocalVersion('user_intakes', intakeId, intakeObject.$2.updatedAt);
    await _hive.intakeBox.putAt(intakeObject.$1, intakeObject.$2);
    await _recalculate([originalDate, intakeObject.$2.dateTime]);
    return _hive.intakeBox.getAt(intakeObject.$1);
  }

  Future<IntakeDBO?> getIntakeById(String intakeId) async {
    return _hive.intakeBox.values
        .firstWhereOrNull((intake) => intake.id == intakeId);
  }

  Future<List<IntakeDBO>> getIntakeRecipe() async {
    return _hive.intakeBox.values
        .where((intake) =>
            intake.meal.nutriments.mealOrRecipe == MealOrRecipeDBO.recipe)
        .toList();
  }

  Future<List<IntakeDBO>> getAllIntakes() async {
    return _hive.intakeBox.values.toList();
  }

  Future<List<IntakeDBO>> getAllIntakesByDate(
      IntakeTypeDBO intakeType, DateTime dateTime) async {
    return _hive.intakeBox.values
        .where((intake) =>
            DateUtils.isSameDay(dateTime, intake.dateTime) &&
            intake.type == intakeType)
        .toList();
  }

  Future<List<IntakeDBO>> getRecentlyAddedIntake({int number = 100}) async {
    final intakeList = _hive.intakeBox.values.indexed.toList();

    // Same-day entries use the last write, then insertion order for ties.
    intakeList.sort((a, b) {
      final byDate = b.$2.dateTime.compareTo(a.$2.dateTime);
      if (byDate != 0) return byDate;
      final byUpdate = b.$2.updatedAt.compareTo(a.$2.updatedAt);
      return byUpdate != 0 ? byUpdate : b.$1.compareTo(a.$1);
    });

    final filterCodes = <String>{};
    final uniqueIntake = intakeList
        .map((entry) => entry.$2)
        .where((intake) =>
            filterCodes.add(intake.meal.code ?? intake.meal.name ?? ""))
        .toList();

    return uniqueIntake.take(number).toList();
  }
}
