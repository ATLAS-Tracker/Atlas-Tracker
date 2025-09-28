import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';

class DailyStepsRecorder {
  final StepsDateDbo stepsBox;
  final Future<void> Function()? onThresholdReached;

  DailyStepsRecorder(
    this.stepsBox, {
    this.onThresholdReached,
  });

  String dayKeyFor(DateTime date) => DateUtils.dateOnly(date).toIso8601String();

  int maybeSaveSteps(int steps) {

    debugPrint('Steps recorded: $steps');

    //final positiveSteps = getStepsWithoutNegative(steps);
    //final initialSteps = initialStep(positiveSteps);
    //stepsBox.nowSteps = getTotalStepsSinceAppInstall(initialSteps);
    unawaited(stepsBox.save());

    onThresholdReached?.call();

    return stepsBox.nowSteps - stepsBox.lastSteps;
  }

  int getTotalStepsSinceAppInstall(int steps) {

    if(steps + stepsBox.diff < stepsBox.nowSteps)
    {
      // A reset happened of the phone
      stepsBox.diff = stepsBox.nowSteps;
      unawaited(stepsBox.save());
    }

    return steps + stepsBox.diff;
  }

  int getStepsWithoutNegative(int steps) {
    if(steps >= 0)
    {
      return steps;
    }
    else if(steps + stepsBox.errorSteps < 0)
    {
      stepsBox.errorSteps = -steps;
      unawaited(stepsBox.save());
      return steps + stepsBox.errorSteps;
    } 
    else if(steps + stepsBox.errorSteps >= 0)
    {
      return steps + stepsBox.errorSteps;
    }
    return steps;
  }

  int initialStep(int steps) {

    if(stepsBox.nowSteps == 0)
    {
      stepsBox.initialStep = steps;
      unawaited(stepsBox.save());
    } 
    else if(steps + stepsBox.diff < stepsBox.nowSteps)
    {
      stepsBox.initialStep = 0;
      unawaited(stepsBox.save());
    }

    return steps - stepsBox.initialStep + 1;
  }
}
