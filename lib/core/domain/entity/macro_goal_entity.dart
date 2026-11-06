import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';

class MacroGoalEntity {
  final String id;
  final DateTime date;

  final double oldCarbsGoal;
  final double oldFatsGoal;
  final double oldProteinsGoal;

  final double newCarbsGoal;
  final double newFatsGoal;
  final double newProteinsGoal;

  MacroGoalEntity({
    required this.id,
    required this.date,
    required this.oldCarbsGoal,
    required this.oldFatsGoal,
    required this.oldProteinsGoal,
    required this.newCarbsGoal,
    required this.newFatsGoal,
    required this.newProteinsGoal,
  });

  static const defaultCarbs = 250.0;
  static const defaultFats = 60.0;
  static const defaultProteins = 120.0;

  /// Keep the current goal B while C is scheduled; never revive B's old A.
  static MacroGoalEntity? fromHistory(
      String owner, List<Map<String, dynamic>> history,
      {required DateTime today, MacroGoalEntity? previous}) {
    final date = DateTime(today.year, today.month, today.day);
    final valid = history
        .where((row) => row['user_id'] == owner && isValidHistoryRow(row))
        .toList()
      ..sort((a, b) =>
          a['start_date'].toString().compareTo(b['start_date'].toString()));
    Map<String, dynamic>? current;
    Map<String, dynamic>? future;
    for (final row in valid) {
      if (DateTime.parse(row['start_date'].toString()).isAfter(date)) {
        future ??= row;
      } else {
        current = row;
      }
    }
    final next = future ?? current;
    if (next == null) return null;
    final fallback = forDay(previous, date);
    double active(String field, double fallback) =>
        (current?[field] as num?)?.toDouble() ?? fallback;
    return MacroGoalEntity(
        id: owner,
        date: DateTime.parse(next['start_date'].toString()),
        oldCarbsGoal: active('carb_goal', fallback.carbs),
        oldFatsGoal: active('fat_goal', fallback.fats),
        oldProteinsGoal: active('protein_goal', fallback.proteins),
        newCarbsGoal: (next['carb_goal'] as num).toDouble(),
        newFatsGoal: (next['fat_goal'] as num).toDouble(),
        newProteinsGoal: (next['protein_goal'] as num).toDouble());
  }

  static bool isValidHistoryRow(Map<String, dynamic> row) {
    if (DateTime.tryParse(row['start_date']?.toString() ?? '') == null) {
      return false;
    }
    final values = [row['carb_goal'], row['fat_goal'], row['protein_goal']];
    if (values.any((value) =>
        value is! num || !value.isFinite || value < 0 || value > 1000)) {
      return false;
    }
    final energy = (values[0] as num) * 4 +
        (values[1] as num) * 9 +
        (values[2] as num) * 4;
    return energy > 0 && energy <= 10000;
  }

  static ({double carbs, double fats, double proteins}) forDay(
      MacroGoalEntity? goal, DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final starts = goal == null
        ? null
        : DateTime(goal.date.year, goal.date.month, goal.date.day);
    final active = starts != null && !date.isBefore(starts);
    return (
      carbs: active ? goal!.newCarbsGoal : goal?.oldCarbsGoal ?? defaultCarbs,
      fats: active ? goal!.newFatsGoal : goal?.oldFatsGoal ?? defaultFats,
      proteins: active
          ? goal!.newProteinsGoal
          : goal?.oldProteinsGoal ?? defaultProteins,
    );
  }

  /// Conversion depuis un DBO Hive
  factory MacroGoalEntity.fromDbo(MacroGoalDbo dbo) {
    return MacroGoalEntity(
      id: dbo.id,
      date: dbo.date,
      oldCarbsGoal: dbo.oldCarbsGoal,
      oldFatsGoal: dbo.oldFatsGoal,
      oldProteinsGoal: dbo.oldProteinsGoal,
      newCarbsGoal: dbo.newCarbsGoal,
      newFatsGoal: dbo.newFatsGoal,
      newProteinsGoal: dbo.newProteinsGoal,
    );
  }

  /// Conversion vers DBO Hive
  MacroGoalDbo toDbo() {
    return MacroGoalDbo(
      id,
      date,
      oldCarbsGoal,
      oldFatsGoal,
      oldProteinsGoal,
      newCarbsGoal,
      newFatsGoal,
      newProteinsGoal,
    );
  }
}
