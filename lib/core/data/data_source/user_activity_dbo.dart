import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

part 'user_activity_dbo.g.dart';

@HiveType(typeId: 10)
@JsonSerializable()
class UserActivityDBO extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double duration;
  @HiveField(2)
  final double burnedKcal;
  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final PhysicalActivityDBO physicalActivityDBO;

  @HiveField(5)
  final DateTime updatedAt;

  UserActivityDBO(this.id, this.duration, this.burnedKcal, this.date,
      this.physicalActivityDBO, this.updatedAt);

  factory UserActivityDBO.fromUserActivityEntity(
      UserActivityEntity userActivityEntity) {
    return UserActivityDBO(
        userActivityEntity.id,
        userActivityEntity.duration,
        userActivityEntity.burnedKcal,
        userActivityEntity.date,
        PhysicalActivityDBO.fromPhysicalActivityEntity(
            userActivityEntity.physicalActivityEntity),
        DateUtilsHelper.roundToSeconds(userActivityEntity.updatedAt));
  }

  factory UserActivityDBO.fromJson(Map<String, dynamic> json) =>
      _$UserActivityDBOFromJson(json);

  Map<String, dynamic> toJson() => _$UserActivityDBOToJson(this);
}
