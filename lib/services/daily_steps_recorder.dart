import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Records daily step counts into Hive with a configurable threshold.
///
/// This encapsulates the logic previously embedded in HomePage to make
/// persistence easy to test without pumping widgets or mocking plugins.
class DailyStepsRecorder {
  final HiveDBProvider hive;
  final int saveThreshold;
  final Future<void> Function()? onThresholdReached;

  DailyStepsRecorder(
    this.hive, {
    this.saveThreshold = 100,
    this.onThresholdReached,
  });

  /// Returns the ISO-8601 key used for the given date (00:00 time).
  String dayKeyFor(DateTime date) => DateUtils.dateOnly(date).toIso8601String();

  /// Maybe persists the provided [steps] for [now]'s day, only if it advanced
  /// by at least [saveThreshold] since the last saved value.
  ///
  /// Returns the last saved steps value after this call (either unchanged
  /// or updated to [steps] if it was saved).
  int maybeSaveSteps(int steps, {DateTime? now}) {
    final date = now ?? DateTime.now();
    final key = dayKeyFor(date);
    final lastSaved = hive.dailyStepsBox.get(key, defaultValue: 0) as int;
    if (steps - lastSaved >= saveThreshold) {
      hive.dailyStepsBox.put(key, steps);
      onThresholdReached?.call();
      return steps;
    }
    return lastSaved;
  }
}

