import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

/// Tracked consumption is a projection of the journal, never a running balance.
class TrackedDayTotals {
  final Box<IntakeDBO> intakes;
  final Box<TrackedDayDBO> days;

  final Box<MacroGoalDbo> goals;

  TrackedDayTotals(this.intakes, this.days, this.goals);

  Future<void> recalculate(Iterable<DateTime> dates,
      {Iterable<TrackedDayDBO> replacements = const []}) async {
    final incoming = {for (final day in replacements) day.day.toDayKey(): day};
    final datesByKey = {for (final date in dates) date.toDayKey(): date};
    final keys = datesByKey.keys.toSet();
    final totals = <String, List<double>>{};
    for (final dbo in intakes.values) {
      final key = dbo.dateTime.toDayKey();
      if (!keys.contains(key)) continue;
      final intake = IntakeEntity.fromIntakeDBO(dbo);
      final sum = totals.putIfAbsent(key, () => [0, 0, 0, 0]);
      sum[0] += intake.totalKcal;
      sum[1] += intake.totalCarbsGram;
      sum[2] += intake.totalFatsGram;
      sum[3] += intake.totalProteinsGram;
    }
    final updates = <String, TrackedDayDBO>{};
    for (final key in keys) {
      var day = incoming[key] ?? days.get(key);
      if (day == null) {
        if (!totals.containsKey(key)) continue;
        final date = datesByKey[key]!;
        final goal = goals.get('macro_goal');
        final macros = MacroGoalEntity.forDay(
            goal == null ? null : MacroGoalEntity.fromDbo(goal), date);
        day = TrackedDayDBO(
            day: DateTime(date.year, date.month, date.day),
            calorieGoal: macroCalories(
                carbs: macros.carbs,
                fat: macros.fats,
                protein: macros.proteins),
            carbsGoal: macros.carbs,
            fatGoal: macros.fats,
            proteinGoal: macros.proteins,
            caloriesTracked: 0,
            updatedAt: DateTime.now().toUtc());
      }
      final sum = totals[key] ?? [0.0, 0.0, 0.0, 0.0];
      if (day.caloriesTracked == sum[0] &&
          day.carbsTracked == sum[1] &&
          day.fatTracked == sum[2] &&
          day.proteinTracked == sum[3]) {
        if (incoming.containsKey(key)) updates[key] = day;
        continue;
      }
      day.caloriesTracked = sum[0];
      day.carbsTracked = sum[1];
      day.fatTracked = sum[2];
      day.proteinTracked = sum[3];
      day.updatedAt = SyncMetadata.nextVersion(day.updatedAt);
      updates[key] = day;
    }
    if (updates.isNotEmpty) await days.putAll(updates);
  }

  Future<void> migrate(Box<bool> migrations) async {
    const key = 'tracked_day_totals_v1';
    if (migrations.get(key) == true) return;
    final normalized = <String, TrackedDayDBO>{};
    final legacyKeys = <dynamic>[];
    for (final storedKey in days.keys.toList()) {
      final day = days.get(storedKey)!;
      final dayKey = day.day.toDayKey();
      if (storedKey != dayKey) legacyKeys.add(storedKey);
      final previous = normalized[dayKey];
      if (previous == null || day.updatedAt.isAfter(previous.updatedAt)) {
        // Hive objects are bound to their original key; copy before rekeying.
        normalized[dayKey] = TrackedDayDBO(
          day: day.day,
          calorieGoal: day.calorieGoal,
          caloriesTracked: day.caloriesTracked,
          carbsGoal: day.carbsGoal,
          carbsTracked: day.carbsTracked,
          fatGoal: day.fatGoal,
          fatTracked: day.fatTracked,
          proteinGoal: day.proteinGoal,
          proteinTracked: day.proteinTracked,
          caloriesBurned: day.caloriesBurned,
          updatedAt: day.updatedAt,
        );
      }
    }
    await recalculate([
      ...normalized.values.map((day) => day.day),
      ...intakes.values.map((intake) => intake.dateTime),
    ], replacements: normalized.values);
    await days.deleteAll(legacyKeys);
    await migrations.put(key, true);
  }
}
