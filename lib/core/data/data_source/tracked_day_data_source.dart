import 'package:opennutritracker/core/data/tracked_day_totals.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'dart:math' as math;

class TrackedDayDataSource {
  final log = Logger('TrackedDayDataSource');
  final HiveDBProvider _hive;

  TrackedDayDataSource(this._hive);

  Future<void> _saveChangedDay(TrackedDayDBO day) async {
    day.updatedAt = SyncMetadata.nextVersion(day.updatedAt);
    await day.save();
  }

  Future<void> saveTrackedDay(TrackedDayDBO trackedDayDBO) async {
    await TrackedDayTotals(
            _hive.intakeBox, _hive.trackedDayBox, _hive.macroGoalBox)
        .recalculate([trackedDayDBO.day], replacements: [trackedDayDBO]);
  }

  Future<void> saveAllTrackedDays(List<TrackedDayDBO> trackedDayDBOList) async {
    await TrackedDayTotals(
            _hive.intakeBox, _hive.trackedDayBox, _hive.macroGoalBox)
        .recalculate(trackedDayDBOList.map((day) => day.day),
            replacements: trackedDayDBOList);
  }

  Future<List<TrackedDayDBO>> getAllTrackedDays() async {
    return _hive.trackedDayBox.values.toList();
  }

  Future<TrackedDayDBO?> getTrackedDay(DateTime day) async {
    return _hive.trackedDayBox.get(day.toDayKey());
  }

  Future<List<TrackedDayDBO>> getTrackedDaysInRange(
      DateTime start, DateTime end) async {
    List<TrackedDayDBO> trackedDays = _hive.trackedDayBox.values
        .where((trackedDay) =>
            (trackedDay.day.isAfter(start) && trackedDay.day.isBefore(end)))
        .toList();
    return trackedDays;
  }

  Future<bool> hasTrackedDay(DateTime day) async =>
      _hive.trackedDayBox.get(day.toDayKey()) != null;

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    log.fine('Updating tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal = calorieGoal;
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Increasing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal += amount;
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Reducing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal -= amount;
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> addDayCaloriesBurned(DateTime day, double addCalories) async {
    log.fine('Adding new burned calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesBurned += addCalories;
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> decreaseDayCaloriesBurned(
      DateTime day, double subtractCalories) async {
    log.fine('Decreasing burned calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      final newValue = updateDay.caloriesBurned - subtractCalories;
      updateDay.caloriesBurned = math.max(0, newValue);
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> updateDayMacroGoals(DateTime day,
      {double? carbsGoal, double? fatGoal, double? proteinGoal}) async {
    log.fine('Updating tracked day macro goals');

    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsGoal != null) {
        updateDay.carbsGoal = carbsGoal;
      }
      if (fatGoal != null) {
        updateDay.fatGoal = fatGoal;
      }
      if (proteinGoal != null) {
        updateDay.proteinGoal = proteinGoal;
      }
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> increaseDayMacroGoal(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {
    log.fine('Increasing tracked day macro goals');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        updateDay.carbsGoal = (updateDay.carbsGoal ?? 0) + carbsAmount;
      }
      if (fatAmount != null) {
        updateDay.fatGoal = (updateDay.fatGoal ?? 0) + fatAmount;
      }
      if (proteinAmount != null) {
        updateDay.proteinGoal = (updateDay.proteinGoal ?? 0) + proteinAmount;
      }
      await _saveChangedDay(updateDay);
    }
  }

  Future<void> reduceDayMacroGoal(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
    log.fine('Reducing tracked day macro goals');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        final updatedCarbs = (updateDay.carbsGoal ?? 0) - carbsAmount;
        updateDay.carbsGoal = math.max(0, updatedCarbs);
      }
      if (fatAmount != null) {
        final updatedFats = (updateDay.fatGoal ?? 0) - fatAmount;
        updateDay.fatGoal = math.max(0, updatedFats);
      }
      if (proteinAmount != null) {
        final updatedProteins = (updateDay.proteinGoal ?? 0) - proteinAmount;
        updateDay.proteinGoal = math.max(0, updatedProteins);
      }

      await _saveChangedDay(updateDay);
    }
  }

  Future<void> deleteTrackedDay(DateTime day) async {
    log.fine('Deleting tracked day from db');
    await _hive.trackedDayBox.delete(day.toDayKey());
  }
}
