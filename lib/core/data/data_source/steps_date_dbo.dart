import 'package:hive_flutter/hive_flutter.dart';

part 'steps_date_dbo.g.dart';

@HiveType(typeId: 21)
class StepsDateDbo extends HiveObject {
  StepsDateDbo({
    this.lastDate,
    this.nowDate,
    this.lastSteps,
    this.nowSteps,
  });

  @HiveField(0)
  DateTime? lastDate;

  @HiveField(1)
  DateTime? nowDate;

  @HiveField(2)
  int? lastSteps;

  @HiveField(3)
  int? nowSteps;
}
