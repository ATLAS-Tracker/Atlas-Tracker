abstract interface class StepTrackingController {
  /// Initializes the controller and returns the initial number of steps to display.
  Future<int> initialize();

  /// Emits step updates that should be reflected in the UI.
  Stream<int> get stepsStream;

  /// Called when the app resumes from background.
  Future<void> handleAppResumed();

  /// Releases resources held by the controller.
  Future<void> dispose();
}
