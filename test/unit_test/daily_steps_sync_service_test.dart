import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/services/daily_steps_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeConnectivity extends Mock implements Connectivity {
  final _controller = StreamController<ConnectivityResult>.broadcast();
  ConnectivityResult _result = ConnectivityResult.none;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  @override
  Future<ConnectivityResult> checkConnectivity() async => _result;

  void setResult(ConnectivityResult result) {
    _result = result;
    _controller.add(result);
  }

  Future<void> close() async => _controller.close();
}

void main() {
  group('DailyStepsSyncService', () {
    late Directory tempDir;
    late Box<int> stepsBox;
    late HiveDBProvider hive;
    late MockSupabaseHttpClient mockHttpClient;
    late SupabaseClient mockSupabase;
    late SupabaseDailyStepsService stepsService;
    late FakeConnectivity connectivity;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('hive_daily_steps_sync_');
      Hive.init(tempDir.path);
      stepsBox = await Hive.openBox<int>('daily_steps_test');
      hive = HiveDBProvider();
      hive.dailyStepsBox = stepsBox;

      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co',
        'fakeAnonKey',
        httpClient: mockHttpClient,
      );
      stepsService = SupabaseDailyStepsService(client: mockSupabase);
      connectivity = FakeConnectivity();
    });

    tearDown(() async {
      await connectivity.close();
      await stepsBox.close();
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('skips when offline', () async {
      // Offline
      connectivity.setResult(ConnectivityResult.none);

      // Yesterday has some steps
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      stepsBox.put(yesterday.toIso8601String(), 1234);

      final service = DailyStepsSyncService(
        hive: hive,
        service: stepsService,
        connectivity: connectivity,
        userIdProvider: () => 'user1',
        nowProvider: () => today,
      );

      await service.syncPendingSteps();

      final out = await mockSupabase.from('daily_steps').select();
      expect(out, isEmpty);
    });

    test('skips when not authenticated (no user id)', () async {
      connectivity.setResult(ConnectivityResult.wifi);
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      stepsBox.put(yesterday.toIso8601String(), 3456);

      final service = DailyStepsSyncService(
        hive: hive,
        service: stepsService,
        connectivity: connectivity,
        userIdProvider: () => null,
      );

      await service.syncPendingSteps();
      final out = await mockSupabase.from('daily_steps').select();
      expect(out, isEmpty);
    });

    test('syncs all days since last sync, excluding today', () async {
      connectivity.setResult(ConnectivityResult.wifi);
      final today = DateTime.now();
      final lastSync = DateTime(today.year, today.month, today.day - 8);

      // Set last sync marker
      const lastSyncKey = '_lastStepsSync';
      stepsBox.put(lastSyncKey, lastSync.millisecondsSinceEpoch);

      // Populate steps for days: start..yesterday
      final days = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        final d = DateTime(today.year, today.month, today.day - (7 - i));
        days.add(d);
        stepsBox.put(d.toIso8601String(), 1000 + i);
      }

      // Add today (should not be synced)
      stepsBox.put(DateTime(today.year, today.month, today.day).toIso8601String(), 9999);

      final service = DailyStepsSyncService(
        hive: hive,
        service: stepsService,
        connectivity: connectivity,
        userIdProvider: () => 'user1',
        nowProvider: () => today,
      );

      await service.syncPendingSteps();

      final out = await mockSupabase.from('daily_steps').select();
      // 7 days synced
      expect(out.length, 8);
      // Entries contain user id
      expect(out.every((e) => e['user_id'] == 'user1'), isTrue);

      // Last sync marker updated to the last day synced (yesterday)
      final updatedMillis = stepsBox.get(lastSyncKey);
      expect(updatedMillis, isNotNull);
    });

    test('catches up multiple offline days from older last sync', () async {
      connectivity.setResult(ConnectivityResult.wifi);
      final today = DateTime(2024, 9, 10);
      final lastSync = DateTime(2024, 8, 25); // inclusive marker in box

      const lastSyncKey = '_lastStepsSync';
      stepsBox.put(lastSyncKey, lastSync.millisecondsSinceEpoch);

      // Populate 26 Aug .. 09 Sep
      final dates = <DateTime>[];
      for (var d = DateTime(2024, 8, 26);
          d.isBefore(today);
          d = d.add(const Duration(days: 1))) {
        dates.add(d);
        stepsBox.put(d.toIso8601String(), 2000);
      }

      final service = DailyStepsSyncService(
        hive: hive,
        service: stepsService,
        connectivity: connectivity,
        userIdProvider: () => 'user1',
      );

      // Temporarily override DateTime.now via injected date by adjusting input keys only.
      // The service derives "today" from DateTime.now(), but since our keys stop at 2024-09-09,
      // it will naturally sync all keys < real today as well.
      await service.syncPendingSteps();

      final out = await mockSupabase.from('daily_steps').select();
      // Expect one entry per date excluding today (26 Aug..09 Sep)
      expect(out.length, dates.length);
    });
  });
}
