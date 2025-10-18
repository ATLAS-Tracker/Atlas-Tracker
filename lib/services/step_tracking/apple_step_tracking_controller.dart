import 'dart:async';

import 'package:daily_pedometer2/daily_pedometer2.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';
import 'package:opennutritracker/services/daily_steps_sync_service.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';

class AppleStepTrackingController implements StepTrackingController {
  AppleStepTrackingController({
    required StepsDateDbo stepsBox,
    required DailyStepsSyncService dailyStepsSyncService,
  })  : _stepsBox = stepsBox,
        _dailyStepsSyncService = dailyStepsSyncService;

  final StepsDateDbo _stepsBox;
  final DailyStepsSyncService _dailyStepsSyncService;

  final _log = Logger('AppleStepTrackingController');
  final _stepsController = StreamController<int>.broadcast();

  StreamSubscription<StepCount>? _subscription;
  int _currentSteps = 0;

  @override
  Stream<int> get stepsStream => _stepsController.stream;

  @override
  Future<int> initialize() async {
    await _ensureCurrentDay();
    _currentSteps = _stepsBox.nowSteps;
    _stepsController.add(_currentSteps);

    _subscription = DailyPedometer2.dailyStepCountStream.listen(
      _handleStepCount,
      onError: _handleError,
    );

    return _currentSteps;
  }

  void _handleStepCount(StepCount event) {
    _currentSteps = event.steps;

    _stepsBox
      ..nowSteps = _currentSteps
      ..lastSteps = _currentSteps
      ..lastDate = _dateOnly(DateTime.now())
      ..diff = 0
      ..errorSteps = 0
      ..initialStep = 0;
    unawaited(_stepsBox.save());

    _stepsController.add(_currentSteps);
    unawaited(_dailyStepsSyncService.syncPendingSteps());
  }

  void _handleError(Object error, [StackTrace? stackTrace]) {
    _log.severe('Daily step count error', error, stackTrace);
  }

  @override
  Future<void> handleAppResumed() async {
    await _ensureCurrentDay();
    _stepsController.add(_currentSteps);
  }

  Future<void> _ensureCurrentDay() async {
    final today = _dateOnly(DateTime.now());
    final lastDate = _stepsBox.lastDate;

    if (lastDate.isBefore(today)) {
      _stepsBox
        ..lastDate = today
        ..nowSteps = 0
        ..lastSteps = 0
        ..diff = 0
        ..errorSteps = 0
        ..initialStep = 0;
      await _stepsBox.save();
      _currentSteps = 0;
      unawaited(_dailyStepsSyncService.syncPendingSteps());
    } else {
      _currentSteps = _stepsBox.nowSteps;
    }
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _stepsController.close();
  }
}
