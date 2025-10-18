import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:opennutritracker/services/step_count/step_count_event.dart';
import 'package:opennutritracker/services/step_count/step_count_provider.dart';

class StepCountService {
  StepCountService(this._stepCountProvider);

  final StepCountProvider? _stepCountProvider;

  Stream<StepCountEvent>? _stepCountStream;
  Future<bool>? _permissionRequest;

  Future<Stream<StepCountEvent>?> getStepCountStream() async {
    if (_stepCountStream != null) {
      return _stepCountStream;
    }

    final provider = _stepCountProvider;
    if (provider == null) {
      return null;
    }

    final hasPermission = await _ensureActivityRecognitionPermission();
    if (!hasPermission) {
      return null;
    }

    _stepCountStream ??= provider.getStepCountStream().asBroadcastStream();
    return _stepCountStream;
  }

  Future<bool> _ensureActivityRecognitionPermission() {
    if (_shouldBypassPermissionRequest()) {
      return Future.value(true);
    }

    final pendingRequest = _permissionRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _requestPermission();
    _permissionRequest = request.then((granted) {
      if (!granted) {
        _permissionRequest = null;
      }
      return granted;
    });

    return _permissionRequest!;
  }

  Future<bool> _requestPermission() async {
    var granted = await Permission.activityRecognition.isGranted;
    if (!granted) {
      granted =
          await Permission.activityRecognition.request() == PermissionStatus.granted;
    }
    return granted;
  }

  bool _shouldBypassPermissionRequest() {
    if (kIsWeb) {
      return true;
    }

    try {
      return !Platform.isAndroid;
    } catch (_) {
      // Platform may throw if not supported (e.g. tests). Assume no permission required.
      return true;
    }
  }
}
