import 'dart:io' show Platform;

import 'package:logging/logging.dart';

import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';

abstract interface class StepTrackingControllerFactory {
  StepTrackingController? create();
}

class PlatformStepTrackingControllerFactory
    implements StepTrackingControllerFactory {
  PlatformStepTrackingControllerFactory({
    required this.androidBuilder,
    required this.appleBuilder,
  });

  final StepTrackingController? Function() androidBuilder;
  final StepTrackingController? Function() appleBuilder;
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
      _log.severe('Failed to determine platform for step tracking', error, stackTrace);
      return null;
    }
    _log.info('No step tracking implementation available for this platform.');
    return null;
  }
}
