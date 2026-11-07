import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

class TrackedDayRepository {
  final TrackedDayDataSource _trackedDayDataSource;

  TrackedDayRepository(this._trackedDayDataSource);

  Future<List<TrackedDayDBO>> getAllTrackedDaysDBO() async {
    return await _trackedDayDataSource.getAllTrackedDays();
  }

  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    final trackedDay = await _trackedDayDataSource.getTrackedDay(day);
    if (trackedDay != null) {
      return TrackedDayEntity.fromTrackedDayDBO(trackedDay);
    } else {
      return null;
    }
  }

  Future<bool> hasTrackedDay(DateTime day) async {
    final trackedDay = await getTrackedDay(day);
    if (trackedDay != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<TrackedDayEntity>> getTrackedDayByRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<TrackedDayDBO> trackedDaysDBO =
        await _trackedDayDataSource.getTrackedDaysInRange(start, end);

    return trackedDaysDBO
        .map(
          (trackedDayDBO) => TrackedDayEntity.fromTrackedDayDBO(trackedDayDBO),
        )
        .toList();
  }

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    await _trackedDayDataSource.updateDayCalorieGoal(day, calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayDataSource.increaseDayCalorieGoal(day, amount);
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayDataSource.reduceDayCalorieGoal(day, amount);
  }

  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async {
    await _trackedDayDataSource.saveTrackedDay(
      TrackedDayDBO(
        day: day,
        calorieGoal: totalKcalGoal,
        caloriesTracked: 0,
        carbsGoal: totalCarbsGoal,
        carbsTracked: 0,
        fatGoal: totalFatGoal,
        fatTracked: 0,
        proteinGoal: totalProteinGoal,
        proteinTracked: 0,
        caloriesBurned: 0,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> addAllTrackedDays(List<TrackedDayDBO> trackedDaysDBO) async {
    await _trackedDayDataSource.saveAllTrackedDays(trackedDaysDBO);
  }

  Future<void> addDayCaloriesBurned(DateTime day, double calories) async {
    await _trackedDayDataSource.addDayCaloriesBurned(day, calories);
  }

  Future<void> removeDayCaloriesBurned(DateTime day, double calories) async {
    await _trackedDayDataSource.decreaseDayCaloriesBurned(day, calories);
  }

  Future<void> updateDayMacroGoal(
    DateTime day, {
    double? carbGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    await _trackedDayDataSource.updateDayMacroGoals(
      day,
      carbsGoal: carbGoal,
      fatGoal: fatGoal,
      proteinGoal: proteinGoal,
    );
  }

  Future<void> increaseDayMacroGoal(
    DateTime day, {
    double? carbGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    await _trackedDayDataSource.increaseDayMacroGoal(
      day,
      carbsAmount: carbGoal,
      fatAmount: fatGoal,
      proteinAmount: proteinGoal,
    );
  }

  Future<void> reduceDayMacroGoal(
    DateTime day, {
    double? carbGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    await _trackedDayDataSource.reduceDayMacroGoal(
      day,
      carbsAmount: carbGoal,
      fatAmount: fatGoal,
      proteinAmount: proteinGoal,
    );
  }

  Future<void> deleteTrackedDay(DateTime day) async {
    await _trackedDayDataSource.deleteTrackedDay(day);
  }
}
