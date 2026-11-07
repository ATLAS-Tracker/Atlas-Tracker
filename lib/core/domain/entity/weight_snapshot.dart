import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

/// Latest real weigh-in, compared with its seven preceding calendar days.
class WeightSnapshot {
  final UserWeightEntity? current;
  final double? previousAverage;

  const WeightSnapshot(this.current, this.previousAverage);

  double? get delta => current == null || previousAverage == null
      ? null
      : current!.weight - previousAverage!;

  /// Empty unless the latest weigh-in was recorded on [day].
  WeightSnapshot onlyOn(DateTime day) => current != null &&
          current!.date.year == day.year &&
          current!.date.month == day.month &&
          current!.date.day == day.day
      ? this
      : const WeightSnapshot(null, null);

  factory WeightSnapshot.at(DateTime day, Iterable<UserWeightEntity> history) {
    DateTime dateOnly(DateTime date) =>
        DateTime(date.year, date.month, date.day);
    final end = dateOnly(day);
    final eligible = history
        .where((entry) => !dateOnly(entry.date).isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (eligible.isEmpty) return const WeightSnapshot(null, null);
    final current = eligible.first;
    final currentDay = dateOnly(current.date);
    final start =
        DateTime(currentDay.year, currentDay.month, currentDay.day - 7);
    final previous = eligible.where((entry) {
      final date = dateOnly(entry.date);
      return !date.isBefore(start) && date.isBefore(currentDay);
    }).toList();
    final average = previous.isEmpty
        ? null
        : previous.fold<double>(0, (sum, entry) => sum + entry.weight) /
            previous.length;
    return WeightSnapshot(current, average);
  }
}
