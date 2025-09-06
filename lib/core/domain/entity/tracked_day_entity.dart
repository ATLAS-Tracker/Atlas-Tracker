import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

class TrackedDayEntity extends Equatable {
  static const maxKcalDifferenceOverGoal = 500;
  static const maxKcalDifferenceUnderGoal = 1000;

  final DateTime day;
  final double calorieGoal;
  final double caloriesTracked;
  final double caloriesBurned;
  final double? carbsGoal;
  final double? carbsTracked;
  final double? fatGoal;
  final double? fatTracked;
  final double? proteinGoal;
  final double? proteinTracked;
  final DateTime updatedAt;

  TrackedDayEntity({
    required this.day,
    required this.calorieGoal,
    required this.caloriesTracked,
    this.caloriesBurned = 0,
    this.carbsGoal,
    this.carbsTracked,
    this.fatGoal,
    this.fatTracked,
    this.proteinGoal,
    this.proteinTracked,
    DateTime? updatedAt,
  }) : updatedAt = DateUtilsHelper.roundToSeconds(updatedAt ?? DateTime.now().toUtc());

  factory TrackedDayEntity.fromTrackedDayDBO(TrackedDayDBO trackedDayDBO) {
    return TrackedDayEntity(
      day: trackedDayDBO.day,
      calorieGoal: trackedDayDBO.calorieGoal,
      caloriesTracked: trackedDayDBO.caloriesTracked,
      caloriesBurned: trackedDayDBO.caloriesBurned,
      carbsGoal: trackedDayDBO.carbsGoal,
      carbsTracked: trackedDayDBO.carbsTracked,
      fatGoal: trackedDayDBO.fatGoal,
      fatTracked: trackedDayDBO.fatTracked,
      proteinGoal: trackedDayDBO.proteinGoal,
      proteinTracked: trackedDayDBO.proteinTracked,
      updatedAt: trackedDayDBO.updatedAt,
    );
  }

  // TODO: make enum class for rating
  Color getCalendarDayRatingColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  Color getRatingDayTextColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.onSecondaryContainer;
    } else {
      return Theme.of(context).colorScheme.onErrorContainer;
    }
  }

  Color getRatingDayTextBackgroundColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.secondaryContainer;
    } else {
      return Theme.of(context).colorScheme.errorContainer;
    }
  }

  bool _hasExceededMaxKcalDifferenceGoal(double calorieGoal, caloriesTracked) {
    double difference = calorieGoal - caloriesTracked;

    if (calorieGoal < caloriesTracked) {
      return difference.abs() < maxKcalDifferenceOverGoal;
    } else {
      return difference < maxKcalDifferenceUnderGoal;
    }
  }

  @override
  List<Object?> get props => [
    day,
    calorieGoal,
    caloriesTracked,
    caloriesBurned,
    carbsGoal,
    carbsTracked,
    fatGoal,
    fatTracked,
    proteinGoal,
    proteinTracked,
    updatedAt,
  ];
}
