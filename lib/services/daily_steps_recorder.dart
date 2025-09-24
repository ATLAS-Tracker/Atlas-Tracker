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

  int maybeSaveSteps(int steps, DateTime eventTime) {

    // Get the box for steps
    final stepsBox = hive.stepsDateBox.get(HiveDBProvider.stepsDateEntryKey);

    // get last saved steps
    final int lastStep = stepsBox?.lastSteps ?? 0;

    if (steps - lastStep >= 0) {
      stepsBox?.nowSteps = steps - lastStep;
    } else {
      stepsBox?.nowSteps = (stepsBox.nowSteps ?? 0) + steps;

    }

    onThresholdReached?.call();
    return stepsBox?.nowSteps ?? 0;
  }
}
