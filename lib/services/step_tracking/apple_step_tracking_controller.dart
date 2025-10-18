import 'dart:async';
import 'package:opennutritracker/services/step_count/step_count_event.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';

class AppleStepTrackingController implements StepTrackingController {
  AppleStepTrackingController();

  final _stepsController = StreamController<int>.broadcast();

  StreamSubscription<StepCountEvent>? _subscription;
  int _currentSteps = 0;

  @override
  Stream<int> get stepsStream => _stepsController.stream;

  @override
  Future<int> initialize() async {
    // TODO(pierrelammers): Implement iOS step tracking initialization.
    const initialSteps = 0;
    _stepsController.add(initialSteps);
    return initialSteps;
  }

  @override
  Future<void> handleAppResumed() async {
    // TODO(pierrelammers): Refresh iOS step data when the app resumes.
  }

  @override
  Future<void> dispose() async {
    await _stepsController.close();
  }
}
