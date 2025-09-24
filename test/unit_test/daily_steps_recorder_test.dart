import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/steps_date_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/services/daily_steps_recorder.dart';

void main() {
  group('DailyStepsRecorder', () {
    late Directory tempDir;
    late Box<int> box;
    late Box<StepsDateDbo> stepsDateBox;
    late HiveDBProvider hive;
    late DailyStepsRecorder recorder;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('hive_steps_recorder_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(StepsDateDboAdapter().typeId)) {
        Hive.registerAdapter(StepsDateDboAdapter());
      }
      box = await Hive.openBox<int>('daily_steps_test');
      stepsDateBox = await Hive.openBox<StepsDateDbo>('steps_date_test');
      hive = HiveDBProvider();
      hive.dailyStepsBox = box;
      hive.stepsDateBox = stepsDateBox;
      recorder = DailyStepsRecorder(hive);
    });

    tearDown(() async {
      await box.close();
      await stepsDateBox.close();
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('saves only every 100 steps for the same day', () async {
      final now = DateTime.now();
      final key = recorder.dayKeyFor(now);

      // Starts empty
      expect(box.get(key), isNull);

      // Below threshold: no save
      final v1 = recorder.maybeSaveSteps(50, now: now);
      expect(v1, 0);
      expect(box.get(key), isNull);

      // At threshold: save
      final v2 = recorder.maybeSaveSteps(100, now: now);
      expect(v2, 100);
      expect(box.get(key), 100);

      // Below next threshold: no save
      final v3 = recorder.maybeSaveSteps(150, now: now);
      expect(v3, 100);
      expect(box.get(key), 100);

      // Next threshold: save again
      final v4 = recorder.maybeSaveSteps(200, now: now);
      expect(v4, 200);
      expect(box.get(key), 200);
    });

    test('respects day change keys', () async {
      final day1 = DateTime(2025, 1, 1, 10, 0, 0);
      final day2 = day1.add(const Duration(days: 1));

      final key1 = recorder.dayKeyFor(day1);
      final key2 = recorder.dayKeyFor(day2);

      // Day 1 saves at 100
      expect(recorder.maybeSaveSteps(99, now: day1), 0);
      expect(box.get(key1), isNull);
      expect(recorder.maybeSaveSteps(100, now: day1), 100);
      expect(box.get(key1), 100);

      // New day: new key, starts from 0
      expect(recorder.maybeSaveSteps(20, now: day2), 0);
      expect(box.get(key2), isNull);
      expect(recorder.maybeSaveSteps(120, now: day2), 120);
      expect(box.get(key2), 120);
    });

    test('invokes callback when threshold reached', () async {
      var called = false;
      recorder = DailyStepsRecorder(
        hive,
        onThresholdReached: () async {
          called = true;
        },
      );

      recorder.maybeSaveSteps(100, now: DateTime.now());
      await Future.delayed(Duration.zero);
      expect(called, isTrue);
    });
  });
}
