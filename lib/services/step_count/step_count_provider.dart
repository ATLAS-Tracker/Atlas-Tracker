import 'step_count_event.dart';

abstract interface class StepCountProvider {
  Stream<StepCountEvent> getStepCountStream();
}
