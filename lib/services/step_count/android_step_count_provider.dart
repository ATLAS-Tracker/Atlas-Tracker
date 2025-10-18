import 'package:pedometer/pedometer.dart';

import 'step_count_event.dart';
import 'step_count_provider.dart';

class AndroidStepCountProvider implements StepCountProvider {
  @override
  Stream<StepCountEvent> getStepCountStream() {
    return Pedometer.stepCountStream.map(
      (event) => StepCountEvent(
        steps: event.steps,
        timestamp: event.timeStamp,
      ),
    );
  }
}
