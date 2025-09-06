import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final HiveDBProvider _hive;

  IntakeDataSource(this._hive);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    _hive.intakeBox.add(intakeDBO);
  }

  Future<void> addAllIntakes(List<IntakeDBO> intakeDBOList) async {
    log.fine('Adding new intake items to db');
    _hive.intakeBox.addAll(intakeDBOList);
  }

  Future<void> deleteIntakeFromId(String intakeId) async {
    log.fine('Deleting intake item from db');
    _hive.intakeBox.values
        .where((dbo) => dbo.id == intakeId)
        .toList()
        .forEach((element) {
      element.delete();
    });
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
    intakeObject.$2.amount = fields['amount'] ?? intakeObject.$2.amount;
    // Always bump updatedAt when mutating an intake
    intakeObject.$2.updatedAt = DateUtilsHelper.roundToSeconds(DateTime.now().toUtc());
    _hive.intakeBox.putAt(intakeObject.$1, intakeObject.$2);
    return _hive.intakeBox.getAt(intakeObject.$1);
  }

  Future<IntakeDBO?> getIntakeById(String intakeId) async {
    return _hive.intakeBox.values
        .firstWhereOrNull((intake) => intake.id == intakeId);
  }

  Future<List<IntakeDBO>> getIntakeRecipe() async {
    return _hive.intakeBox.values
        .where((intake) => intake.meal.nutriments.mealOrRecipe == MealOrRecipeDBO.recipe)
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
    final intakeList = _hive.intakeBox.values.toList();

    //  sort list by date (newest first) and filter unique intake
    intakeList.sort((a, b) => (-1) * a.dateTime.compareTo(b.dateTime));

    final filterCodes = <String>{};
    final uniqueIntake = intakeList
        .where((intake) =>
            filterCodes.add(intake.meal.code ?? intake.meal.name ?? ""))
        .toList();

    return uniqueIntake.take(number).toList();
  }
}
