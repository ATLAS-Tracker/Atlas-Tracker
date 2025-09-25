import 'package:hive_flutter/hive_flutter.dart';

part 'daily_steps_queue_entry.g.dart';

@HiveType(typeId: 23)
class DailyStepsQueueEntry extends HiveObject {
  DailyStepsQueueEntry({
    required this.date,
    required this.steps,
    required this.queuedAt,
  });

  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int steps;

  @HiveField(2)
  final DateTime queuedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStepsQueueEntry && other.date == date;

  @override
  int get hashCode => date.hashCode;
}
