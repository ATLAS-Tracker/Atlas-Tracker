import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/services/nutrition_widget_actions.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = NutritionWidgetActions.channel;
  const codec = StandardMethodCodec();
  late NutritionWidgetActions actions;
  late List<String> opened;
  String? pending;

  Future<void> notify() async {
    final done = Completer<void>();
    binding.channelBuffers.push(
      channel.name,
      codec.encodeMethodCall(const MethodCall('actionAvailable')),
      (ByteData? response) => done.complete(),
    );
    await done.future;
  }

  setUp(() {
    actions = NutritionWidgetActions();
    opened = [];
    pending = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      expect(call.method, 'takeAction');
      final action = pending;
      pending = null;
      return action;
    });
  });

  tearDown(() {
    actions.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('consumes a cold-start scan once when the main screen is ready',
      () async {
    pending = 'scan';
    actions.start(opened.add);
    await Future<void>.delayed(Duration.zero);
    await notify();
    expect(opened, ['scan']);
    expect(pending, isNull);
  });

  test('handles distinct scan and add actions while the app is running',
      () async {
    actions.start(opened.add);
    await Future<void>.delayed(Duration.zero);
    for (final action in ['scan', 'add', 'scan']) {
      pending = action;
      await notify();
    }
    expect(opened, ['scan', 'add', 'scan']);
  });

  test('ignores absent and unsupported actions', () async {
    actions.start(opened.add);
    await Future<void>.delayed(Duration.zero);
    pending = 'unknown';
    await notify();
    expect(opened, isEmpty);
  });

  test('does not navigate if disposed while waiting for Android', () async {
    final response = Completer<String?>();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => response.future);
    actions.start(opened.add);
    actions.dispose();
    response.complete('scan');
    await Future<void>.delayed(Duration.zero);
    expect(opened, isEmpty);
  });

  test('is harmless on platforms without a native widget', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    actions.start(opened.add);
    await Future<void>.delayed(Duration.zero);
    expect(opened, isEmpty);
  });
}
