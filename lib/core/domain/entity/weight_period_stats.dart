import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

/// Weight figures over the [days] calendar days ending on (and including) a day.
class WeightPeriodStats {
  /// Weigh-in recorded on the day itself, never an older one.
  final double? today;

  /// Mean of the period's weigh-ins, today included.
  final double? average;

  /// Today minus the period's first weigh-in; null without both.
  final double? change;

  /// One weigh-in per day, oldest first, inside the period.
  final List<UserWeightEntity> weighIns;

  const WeightPeriodStats._(
      this.today, this.average, this.change, this.weighIns);

  double? get deltaToAverage =>
      today == null || average == null ? null : today! - average!;

  factory WeightPeriodStats.of(
      DateTime day, Iterable<UserWeightEntity> history, int days) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final end = dateOnly(day);
    final start = DateTime(end.year, end.month, end.day - days + 1);
    final byDay = <DateTime, UserWeightEntity>{};
    for (final entry in history) {
      final date = dateOnly(entry.date);
      if (date.isBefore(start) || date.isAfter(end)) continue;
      byDay[date] = entry;
    }
    final keys = byDay.keys.toList()..sort();
    final weighIns = [for (final k in keys) byDay[k]!];
    if (weighIns.isEmpty) {
      return const WeightPeriodStats._(null, null, null, []);
    }
    final today = keys.last == end ? weighIns.last.weight : null;
    final average =
        weighIns.fold<double>(0, (sum, e) => sum + e.weight) / weighIns.length;
    final change = today == null || weighIns.length < 2
        ? null
        : today - weighIns.first.weight;
    return WeightPeriodStats._(today, average, change, weighIns);
  }
}
