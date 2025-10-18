import 'dart:io' show Platform;

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';

abstract interface class StepTrackingControllerFactory {
  StepTrackingController? create();

  int dailyStepsFromBox(StepsDateDbo stepsBox);
}

class PlatformStepTrackingControllerFactory
    implements StepTrackingControllerFactory {
  PlatformStepTrackingControllerFactory({
    required this.androidBuilder,
    required this.appleBuilder,
    required this.androidStepsCalculator,
    required this.appleStepsCalculator,
    required this.defaultStepsCalculator,
  });

  final StepTrackingController? Function() androidBuilder;
  final StepTrackingController? Function() appleBuilder;
  final int Function(StepsDateDbo stepsBox) androidStepsCalculator;
  final int Function(StepsDateDbo stepsBox) appleStepsCalculator;
  final int Function(StepsDateDbo stepsBox) defaultStepsCalculator;
  final _log = Logger('PlatformStepTrackingControllerFactory');

  @override
  StepTrackingController? create() {
    try {
      if (Platform.isAndroid) {
        return androidBuilder();
      }
      if (Platform.isIOS) {
        return appleBuilder();
      }
    } catch (error, stackTrace) {
      _log.severe(
        'Failed to determine platform for step tracking',
        error,
        stackTrace,
      );
      return null;
    }
    _log.info('No step tracking implementation available for this platform.');
    return null;
  }

  @override
  int dailyStepsFromBox(StepsDateDbo stepsBox) {
    try {
      if (Platform.isAndroid) {
        return androidStepsCalculator(stepsBox);
      }
      if (Platform.isIOS) {
        return appleStepsCalculator(stepsBox);
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to evaluate platform while computing daily steps; using default calculator.',
        error,
        stackTrace,
      );
    }
    return defaultStepsCalculator(stepsBox);
  }
}
