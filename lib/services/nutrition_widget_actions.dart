import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android keeps an action pending until the authenticated main screen is ready.
class NutritionWidgetActions {
  static const channel =
      MethodChannel('com.atlastracker.android/nutrition_widget');
  bool _disposed = false;

  void start(ValueChanged<String> onAction) {
    Future<void> consume() async {
      try {
        final action = await channel.invokeMethod<String>('takeAction');
        if (!_disposed && (action == 'scan' || action == 'add')) {
          onAction(action!);
        }
      } on MissingPluginException {
        // Home-screen actions are only implemented on Android.
      } on PlatformException catch (error) {
        debugPrint('Could not open widget action: ${error.code}');
      }
    }

    channel.setMethodCallHandler((call) async {
      if (call.method == 'actionAvailable') await consume();
    });
    unawaited(consume());
  }

  void dispose() {
    _disposed = true;
    channel.setMethodCallHandler(null);
  }
}
