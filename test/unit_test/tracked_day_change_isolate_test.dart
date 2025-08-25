import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/sync/tracked_day_change_isolate.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class FakeConnectivity extends Mock implements Connectivity {
  final _controller = StreamController<ConnectivityResult>.broadcast();
  ConnectivityResult _result = ConnectivityResult.none;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  @override
  Future<ConnectivityResult> checkConnectivity() async => _result;

  void emit(ConnectivityResult result) {
    _result = result;
    _controller.add(result);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

/// Utility function to wait for a condition to become true, with timeout
Future<void> waitForCondition(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (await condition()) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  throw TimeoutException('Condition not met within $timeout');
}

void main() {
  group('TrackedDayChangeIsolate', () {
    late Directory tempDir;
    late Box<TrackedDayDBO> box;
    late TrackedDayChangeIsolate watcher;
    late FakeConnectivity connectivity;
    late SupabaseClient mockSupabase;
    late MockSupabaseHttpClient mockHttpClient;
    late SupabaseTrackedDayService trackedDayService;
    late TrackedDayRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Setup Hive in temporary directory
      tempDir = await Directory.systemTemp.createTemp('hive_test_isolate_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(trackedDayDBOTypeId)) {
        Hive.registerAdapter(TrackedDayDBOAdapter());
      }
      box = await Hive.openBox<TrackedDayDBO>('tracked_day_test');
      final hive = HiveDBProvider();
      hive.trackedDayBox = box;

      // Initialize repository with the Hive box
      repo = TrackedDayRepository(TrackedDayDataSource(hive));

      // Setup mock Supabase client using mock-supabase-http-client
      mockHttpClient = MockSupabaseHttpClient();
      mockSupabase = SupabaseClient(
        'https://mock.supabase.co',
        'fakeAnonKey',
        httpClient: mockHttpClient,
      );
      trackedDayService = SupabaseTrackedDayService(client: mockSupabase);

      // Setup fake connectivity
      connectivity = FakeConnectivity();

      // Create and start the isolate watcher
      watcher = TrackedDayChangeIsolate(
        box,
        service: trackedDayService,
        connectivity: connectivity,
      );
      await watcher.start();
    });

    tearDown(() async {
      await watcher.stop();
      await connectivity.close();
      await box.close();
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('captures modified day when box updates', () async {
      final day = DateTime.utc(2024, 1, 1);

      // Simulate a local update
      await repo.addNewTrackedDay(day, 1, 0, 0, 0);

      // Wait for the isolate to detect the modification
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).contains(day));

      // Check that the modified day is captured
      final modifiedDays = await watcher.getModifiedDays();
      expect(modifiedDays, contains(day));
    });

    test('stores unique days when multiple updates occur', () async {
      final day1 = DateTime.utc(2024, 1, 1);
      final day2 = DateTime.utc(2024, 1, 2);

      // Simulate two different updates and one repeated update
      await repo.addNewTrackedDay(day1, 1, 0, 0, 0);
      await repo.addNewTrackedDay(day2, 1, 0, 0, 0);
      await repo.addNewTrackedDay(day1, 1, 0, 0, 0);

      // Ensure both days are captured and stored uniquely
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).length >= 2);

      final modified = await watcher.getModifiedDays();
      expect(modified.toSet(), {day1, day2});
    });

    test('syncs modified days when connectivity is restored', () async {
      final day = DateTime.utc(2024, 1, 3);

      // Simulate local addition (offline mode)
      await repo.addNewTrackedDay(day, 1, 0, 0, 0);

      // Wait until isolate has captured the modified day
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).contains(day));
      expect((await watcher.getModifiedDays()).contains(day), isTrue);

      // Simulate connectivity restoration (e.g. Wi-Fi comes back)
      connectivity.emit(ConnectivityResult.wifi);

      // Wait for the isolate to sync and clear the modified day set
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).isEmpty);
      expect(await watcher.getModifiedDays(), isEmpty);

      // Check that the tracked day was actually sent to the mock Supabase backend
      final result = await mockSupabase.from('tracked_days').select();
      expect(result.length, 1);
      expect(result.first['day'], day.toIso8601String().split('T').first);
    });

    test('syncs without connectivity restoration', () async {
      // Simulate connectivity restoration (e.g. Wi-Fi comes back)
      connectivity.emit(ConnectivityResult.none);

      final day = DateTime.utc(2024, 1, 3);

      // Simulate local addition (offline mode)
      await repo.addNewTrackedDay(day, 1, 2, 3, 4);

      // Wait until isolate has captured the modified day
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).contains(day));
      expect((await watcher.getModifiedDays()).contains(day), isTrue);

      // Wait 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Check that the isolate still has the modified day
      final modifiedDays = await watcher.getModifiedDays();
      expect(modifiedDays, contains(day));
      // Check that supabase has not received the day yet
      final result = await mockSupabase.from('tracked_days').select();
      expect(result.length, 0);

      // Simulate connectivity restoration (e.g. Wi-Fi comes back)
      connectivity.emit(ConnectivityResult.wifi);

      // Wait for the isolate to sync and clear the modified day set
      await waitForCondition(
          () async => (await watcher.getModifiedDays()).isEmpty);
      expect(await watcher.getModifiedDays(), isEmpty);

      // Check that the tracked day was actually sent to the mock Supabase backend
      final output = await mockSupabase.from('tracked_days').select();
      expect(output.length, 1);
      expect(output.first['day'], day.toIso8601String().split('T').first);
    });

    test('check values store on the remote', () async {
      final day = DateTime.utc(2024, 1, 1);

      // Simule une mise à jour locale en ajoutant un nouveau jour suivi
      await repo.addNewTrackedDay(day, 2, 2, 2, 2);

      // Plusieurs modifications hors ligne
      await repo.addDayMacrosTracked(
        day,
        carbsTracked: 2,
        fatTracked: 2,
        proteinTracked: 2,
      );
      await repo.addDayMacrosTracked(
        day,
        carbsTracked: 3,
        fatTracked: 3,
        proteinTracked: 3,
      );
      await repo.addDayTrackedCalories(day, 10);

      // Attendre que l’isolate détecte la modification
      await waitForCondition(
        () async => (await watcher.getModifiedDays()).contains(day),
      );

      // Vérifie que le jour modifié est bien capturé
      final modifiedDays = await watcher.getModifiedDays();
      expect(modifiedDays, contains(day));

      // Simule le retour de la connectivité (ex: Wi-Fi rétabli)
      connectivity.emit(ConnectivityResult.wifi);

      // Attendre que l’isolate synchronise et nettoie les jours modifiés
      await waitForCondition(
        () async => (await watcher.getModifiedDays()).isEmpty,
      );
      expect(await watcher.getModifiedDays(), isEmpty);

      // Vérifie que le jour suivi a bien été envoyé dans Supabase mock
      final result = await mockSupabase.from('tracked_days').select();
      expect(result.length, 1);

      final remote = result.first;
      final remoteDay = remote['day'] as String;
      expect(remoteDay, day.toIso8601String().split('T').first);

      expect(remote['calorieGoal'], 2);
      expect(remote['caloriesTracked'], 10);
      expect(remote['carbsGoal'], 2);
      expect(remote['carbsTracked'], 5);
      expect(remote['fatGoal'], 2);
      expect(remote['fatTracked'], 5);
      expect(remote['proteinGoal'], 2);
      expect(remote['proteinTracked'], 5);

      // Vérifie que les données distantes correspondent bien au local
      final dbo = box.get(day.toParsedDay());
      expect(dbo, isNotNull);

      // Adapter la comparaison : ignorer la différence de format de 'day'
      final expected = {
        'day': day.toIso8601String().split('T').first,
        'calorieGoal': 2.0,
        'caloriesTracked': 10.0,
        'carbsGoal': 2.0,
        'carbsTracked': 5.0,
        'fatGoal': 2.0,
        'fatTracked': 5.0,
        'proteinGoal': 2.0,
        'proteinTracked': 5.0,
        'updated_at': remote['updated_at'],
        'caloriesBurned': 0.0,
      };

      expect(remote, equals(expected));
      expect(remote, equals(dbo!.toJson()));
    });
  });
}
