import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class DailyStepsRecorder {
  final HiveDBProvider hive;
  final Future<void> Function()? onThresholdReached;

  DailyStepsRecorder(
    this.hive, {
    this.onThresholdReached,
  });

  String dayKeyFor(DateTime date) => DateUtils.dateOnly(date).toIso8601String();

  void maybeSaveSteps(int steps, DateTime now) {
    hive.dailyStepsBox.put(dayKeyFor(now), steps);
    onThresholdReached?.call();
  }
}

