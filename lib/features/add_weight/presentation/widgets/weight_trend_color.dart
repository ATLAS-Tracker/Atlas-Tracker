import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';

Color weightTrendColor({
  required double deltaKg,
  required UserWeightGoalEntity goal,
  required ColorScheme colors,
}) {
  final isOnTarget = switch (goal) {
    UserWeightGoalEntity.loseWeight => deltaKg < 0,
    UserWeightGoalEntity.gainWeight => deltaKg > 0,
    UserWeightGoalEntity.maintainWeight => deltaKg.abs() <= 0.2,
  };
  return isOnTarget ? lunchColor : colors.error;
}
