class StepCountEvent {
  const StepCountEvent({
    required this.steps,
    required this.timestamp,
  });

  final int steps;
  final DateTime timestamp;
}
