import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

class UserWeightEntity {
  final String id;
  final double weight;
  final DateTime date;
  final DateTime updatedAt;

  UserWeightEntity({
    required this.id,
    required this.weight,
    required this.date,
    DateTime? updatedAt,
  }) : updatedAt = DateUtilsHelper.roundToSeconds(updatedAt ?? DateTime.now().toUtc());

  factory UserWeightEntity.fromUserWeightDbo(UserWeightDbo userWeightDbo) {
    return UserWeightEntity(
      id: userWeightDbo.id,
      weight: userWeightDbo.weight,
      date: userWeightDbo.date,
      updatedAt: userWeightDbo.updatedat,
    );
  }

  static getIconData() => Icons.monitor_weight_outlined;
}
