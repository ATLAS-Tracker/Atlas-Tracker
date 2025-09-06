import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

class UserActivityEntity extends Equatable {
  final String id;
  final double duration;
  final double burnedKcal;
  final DateTime date;
  final DateTime updatedAt;

  final PhysicalActivityEntity physicalActivityEntity;

  UserActivityEntity(
    this.id,
    this.duration,
    this.burnedKcal,
    this.date,
    this.physicalActivityEntity, {
    DateTime? updatedAt,
  }) : updatedAt = DateUtilsHelper.roundToSeconds(updatedAt ?? DateTime.now().toUtc());

  factory UserActivityEntity.fromUserActivityDBO(UserActivityDBO activityDBO) {
    return UserActivityEntity(
      activityDBO.id,
      activityDBO.duration,
      activityDBO.burnedKcal,
      activityDBO.date,
      PhysicalActivityEntity.fromPhysicalActivityDBO(
        activityDBO.physicalActivityDBO,
      ),
      updatedAt: activityDBO.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, duration, burnedKcal, date, updatedAt];

  static getIconData() => Icons.directions_run_outlined;
}
