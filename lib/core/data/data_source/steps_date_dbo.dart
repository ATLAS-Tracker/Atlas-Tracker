import 'package:hive_flutter/hive_flutter.dart';

part 'steps_date_dbo.g.dart';

@HiveType(typeId: 21)
class StepsDateDbo extends HiveObject {
  StepsDateDbo({
    required this.lastSteps,
    required this.nowSteps,
    required this.diff,
    required this.lastDate,
  });

  @HiveField(0)
  int lastSteps = 0;

  @HiveField(1)
  int nowSteps = 0;

  @HiveField(2)
  int diff = 0;

  @HiveField(3)
  DateTime lastDate = DateTime.now();

  @HiveField(4)
  int errorSteps = 0;
}
