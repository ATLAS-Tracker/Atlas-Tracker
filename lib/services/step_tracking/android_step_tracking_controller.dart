import 'dart:async';

import 'package:logging/logging.dart';

import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';
import 'package:opennutritracker/services/daily_steps_recorder.dart';
import 'package:opennutritracker/services/daily_steps_sync_service.dart';
import 'package:opennutritracker/services/step_count/step_count_event.dart';
import 'package:opennutritracker/services/step_count_service.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';

class AndroidStepTrackingController implements StepTrackingController {
  AndroidStepTrackingController({
    required StepCountService stepCountService,
    required StepsDateDbo stepsBox,
    required DailyStepsSyncService dailyStepsSyncService,
  })  : _stepCountService = stepCountService,
        _stepsBox = stepsBox,
        _stepsRecorder = DailyStepsRecorder(
          stepsBox,
          onThresholdReached: dailyStepsSyncService.syncPendingSteps,
        );

  final StepCountService _stepCountService;
  final StepsDateDbo _stepsBox;
  final DailyStepsRecorder _stepsRecorder;

  final _log = Logger('AndroidStepTrackingController');
  final _stepsController = StreamController<int>.broadcast();

  StreamSubscription<StepCountEvent>? _subscription;
  int _currentSteps = 0;

  @override
  Stream<int> get stepsStream => _stepsController.stream;

  @override
  Future<int> initialize() async {
    await _resetStepsIfDayChanged();
    _currentSteps = _stepsBox.nowSteps - _stepsBox.lastSteps;
    _stepsController.add(_currentSteps);

    final stream = await _stepCountService.getStepCountStream();
    if (stream == null) {
      _log.warning(
        'Activity recognition permission not granted; disabling step tracking.',
      );
      return _currentSteps;
    }

    _subscription = stream.listen(
      _handleStepCount,
      onError: _handleError,
    );

    return _currentSteps;
  }

  @override
  Future<void> handleAppResumed() async {
    await _resetStepsIfDayChanged();
    _currentSteps = _stepsBox.nowSteps - _stepsBox.lastSteps;
    _stepsController.add(_currentSteps);
  }

  void _handleStepCount(StepCountEvent event) {
    if (_stepsBox.lastDate.isBefore(event.timestamp)) {
      unawaited(_resetStepsIfDayChanged());
    }

    final correctedSteps = _stepsRecorder.maybeSaveSteps(event.steps);
    _currentSteps = correctedSteps;
    _stepsController.add(_currentSteps);
  }

  void _handleError(Object error) {
    _log.severe('StepCount error: $error');
    _currentSteps = _stepsBox.nowSteps - _stepsBox.lastSteps;
    _stepsController.add(_currentSteps);
  }

  Future<void> _resetStepsIfDayChanged() async {
    final today = _dateOnly(DateTime.now());
    final lastDate = _stepsBox.lastDate;

    if (lastDate.isBefore(today)) {
      _stepsBox
        ..lastDate = today
        ..lastSteps = _stepsBox.nowSteps
        ..nowSteps = _stepsBox.nowSteps
        ..diff = _stepsBox.diff
        ..errorSteps = _stepsBox.errorSteps;

      await _stepsBox.save();
      _currentSteps = 0;
    }
  }

  DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _stepsController.close();
  }
}
