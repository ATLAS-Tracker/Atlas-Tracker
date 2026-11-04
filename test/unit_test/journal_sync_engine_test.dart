import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import '../fixture/intake_for_recipe_fixtures.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/sync/journal_sync_engine.dart';

class FakeAuth extends Mock implements GoTrueClient {}

class FakeClient extends Mock implements SupabaseClient {}

class FakeConfig extends Mock implements ConfigRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late HiveDBProvider hive;
  late JournalSyncEngine engine;
  late SupabaseClient transport;
  late UserWeightDataSource weights;
  late Map<String, List<Map<String, dynamic>>> remote;
  late List<http.Request> requests;
  Future<void> Function()? beforeWrite;
  var legacy = false;
  const owner = '00000000-0000-4000-8000-000000000001';
  final day = DateTime(2026, 11, 3);
  final stamp = DateTime.utc(2026, 11, 3, 8);

  setUpAll(() {
    Hive.registerAdapter(UserWeightDboAdapter());
    Hive.registerAdapter(TrackedDayDBOAdapter());
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(MealDBOAdapter());
    Hive.registerAdapter(MealSourceDBOAdapter());
    Hive.registerAdapter(MealNutrimentsDBOAdapter());
    Hive.registerAdapter(MealOrRecipeDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atlas_sync_engine_');
    Hive.init(directory.path);
    hive = HiveDBProvider(userId: owner);
    hive.intakeBox = await Hive.openBox<IntakeDBO>('intakes');
    hive.recipeBox = await Hive.openBox<RecipesDBO>('recipes');
    hive.trackedDayBox = await Hive.openBox<TrackedDayDBO>('days');
    hive.userWeightBox = await Hive.openBox<UserWeightDbo>('weights');
    hive.macroGoalBox = await Hive.openBox<MacroGoalDbo>('goals');
    hive.syncMetadataBox = await Hive.openBox<String>('metadata');
    remote = {};
    requests = [];
    beforeWrite = null;
    legacy = false;
    transport = SupabaseClient('https://test.invalid', 'key',
        httpClient: MockClient((request) async {
      requests.add(request);
      final table = request.url.pathSegments.last;
      http.Response failure(String code) => http.Response(
          jsonEncode({'code': code, 'message': 'Deployed schema fixture'}), 400,
          request: request, headers: {'content-type': 'application/json'});
      if (legacy && ['user_intakes', 'user_recipes'].contains(table)) {
        return failure('PGRST205');
      }
      if (request.method == 'GET') {
        if (legacy &&
            request.url.queryParameters['select']?.contains('modified_at') ==
                true) {
          return failure('42703');
        }
        // Deliberately return a foreign row too: the merge must reject it.
        return http.Response(jsonEncode(remote[table] ?? []), 200,
            request: request, headers: {'content-type': 'application/json'});
      }
      await beforeWrite?.call();
      if (request.method == 'DELETE') {
        remote[table]?.removeWhere((row) =>
            request.url.queryParameters['user_id'] == 'eq.${row['user_id']}' &&
            request.url.queryParameters['date'] == 'eq.${row['date']}');
        return http.Response('', 204, request: request);
      }
      final rows =
          (jsonDecode(request.body) as List).cast<Map<String, dynamic>>();
      if (legacy &&
          rows.any((row) =>
              row.containsKey('modified_at') ||
              row.containsKey('deleted_at') ||
              (table == 'user_weight' && row.containsKey('updated_at')))) {
        return failure('PGRST204');
      }
      final stored = remote.putIfAbsent(table, () => []);
      final key = table == 'user_weight'
          ? 'date'
          : table == 'tracked_days'
              ? 'day'
              : 'record_id';
      for (final row in rows) {
        if (legacy) {
          row[table == 'user_weight' ? 'updatedat' : 'updated_at'] =
              DateTime.now().toUtc().toIso8601String();
        }
        stored.removeWhere(
            (old) => old[key] == row[key] && old['user_id'] == row['user_id']);
        stored.add(row);
      }
      return http.Response('', 201, request: request);
    }));
    final auth = FakeAuth();
    when(() => auth.currentUser).thenReturn(User(
        id: owner,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01'));
    final client = FakeClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.from(any())).thenAnswer(
        (call) => transport.from(call.positionalArguments.single as String));
    final config = FakeConfig();
    when(() => config.getSupabaseSyncEnabled()).thenAnswer((_) async => true);
    weights = UserWeightDataSource(hive);
    engine = JournalSyncEngine(
        hive: hive,
        client: client,
        config: config,
        intakes: IntakeRepository(IntakeDataSource(hive)),
        recipes: RecipeRepository(RecipesDataSource(hive)),
        days: TrackedDayRepository(TrackedDayDataSource(hive)),
        weights: UserWeightRepository(weights),
        requestTimeout: const Duration(milliseconds: 100));
  });
  tearDown(() async {
    await engine.stop();
    await transport.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Map<String, dynamic> row(String user, double weight, DateTime version,
          {bool deleted = false}) =>
      {
        'user_id': user,
        'id': 'weight',
        'date': '2026-11-03',
        'weight': weight,
        'modified_at': version.toIso8601String(),
        'updated_at': version.toIso8601String(),
        'deleted_at': deleted ? version.toIso8601String() : null,
      };

  test('pull is owner-scoped and newest weight wins over stale local data',
      () async {
    await weights.addAllUserWeights([UserWeightDbo('weight', 90, day, stamp)]);
    remote['user_weight'] = [
      row(owner, 80, stamp.add(const Duration(hours: 1))),
      {...row('foreign', 60, stamp), 'date': '2026-11-02'}
    ];
    await engine.sync();
    expect(hive.userWeightBox.values.single.weight, 80);
    expect(
        requests
            .where((r) => r.method == 'GET')
            .every((r) => r.url.queryParameters['user_id'] == 'eq.$owner'),
        isTrue);
  });

  test('remote deletion persists and cannot resurrect from an older device',
      () async {
    await weights.addAllUserWeights([UserWeightDbo('weight', 90, day, stamp)]);
    final deleted = stamp.add(const Duration(hours: 1));
    remote['user_weight'] = [row(owner, 0, deleted, deleted: true)];
    await engine.sync();
    expect(hive.userWeightBox.values, isEmpty);
    expect(
        SyncMetadata(hive.syncMetadataBox)
            .deletedAt('user_weight', '2026-11-03'),
        deleted);
    remote['user_weight'] = [row(owner, 90, stamp)];
    await engine.sync();
    expect(hive.userWeightBox.values, isEmpty);
    expect(remote['user_weight']!.single['deleted_at'], isNotNull);
  });

  test('an edit while upload is in flight is sent in a following pass',
      () async {
    await weights.addUserWeight(UserWeightDbo('weight', 80, day, stamp));
    final entered = Completer<void>();
    final release = Completer<void>();
    beforeWrite = () async {
      beforeWrite = null;
      entered.complete();
      await release.future;
    };
    final running = engine.sync();
    await entered.future;
    await weights.addUserWeight(UserWeightDbo('weight', 81, day, stamp));
    final requested = engine.sync();
    release.complete();
    await Future.wait([running, requested]);
    expect(remote['user_weight']!.single['weight'], 81);
    expect(requests.where((r) => r.method == 'POST'), hasLength(2));
  });

  test('coach goals do not erase a newer pending activity value', () async {
    await hive.trackedDayBox.put(
        '2026-11-03',
        TrackedDayDBO(
            day: day,
            calorieGoal: 2000,
            caloriesTracked: 0,
            carbsTracked: 0,
            fatTracked: 0,
            proteinTracked: 0,
            caloriesBurned: 100,
            updatedAt: stamp.add(const Duration(hours: 2))));
    remote['tracked_days'] = [
      {
        'user_id': owner,
        'day': '2026-11-03',
        'calorieGoal': 2100,
        'caloriesTracked': 0,
        'carbsTracked': 0,
        'fatTracked': 0,
        'proteinTracked': 0,
        'caloriesBurned': 0,
        'modified_at': stamp.toIso8601String(),
        'updated_at': stamp.toIso8601String(),
      }
    ];
    await engine.sync();
    expect(hive.trackedDayBox.get('2026-11-03')!.calorieGoal, 2100);
    expect(hive.trackedDayBox.get('2026-11-03')!.caloriesBurned, 100);
    expect(remote['tracked_days']!.single['caloriesBurned'], 100);
  });

  test('a timed out upload keeps the local deletion for retry', () async {
    await weights.deleteUserWeightByDate(day);
    final release = Completer<void>();
    beforeWrite = () => release.future;
    await engine.sync();
    expect(
        SyncMetadata(hive.syncMetadataBox)
            .deletedAt('user_weight', '2026-11-03'),
        isNotNull);
    release.complete();
    beforeWrite = null;
    await Future<void>.delayed(Duration.zero);
    await engine.sync();
    expect(remote['user_weight']!.single['deleted_at'], isNotNull);
  });

  test(
      'legacy production receives prepared weights and totals without new columns',
      () async {
    legacy = true;
    await engine.intakes.addIntake(IntakeEntity(
        id: 'meal',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: IntakeForRecipeFixtures.chicken.meal!,
        dateTime: day));
    await weights.addUserWeight(
        UserWeightDbo('00000000-0000-4000-8000-000000000099', 80, day, stamp));
    await engine.sync();
    expect(remote['user_weight']?.single['weight'], 80);
    expect(remote['user_weight']!.single['updatedat'], isNotNull);
    expect(remote['tracked_days']?.single['caloriesTracked'], 165);
    expect(
        requests.any((r) =>
            ['user_intakes', 'user_recipes'].contains(r.url.pathSegments.last)),
        isFalse);
  });

  test('legacy updatedat pulls a newer weight and deletion stays owner scoped',
      () async {
    legacy = true;
    await weights.addAllUserWeights([UserWeightDbo('weight', 90, day, stamp)]);
    remote['user_weight'] = [
      {
        'user_id': owner,
        'id': '00000000-0000-4000-8000-000000000099',
        'date': '2026-11-03',
        'weight': 80,
        'updatedat': stamp.add(const Duration(hours: 1)).toIso8601String()
      },
      {
        'user_id': 'foreign',
        'id': 'other',
        'date': '2026-11-03',
        'weight': 70,
        'updatedat': stamp.toIso8601String()
      },
    ];
    await engine.sync();
    expect(hive.userWeightBox.values.single.weight, 80);
    await weights.deleteUserWeightByDate(day);
    await engine.sync();
    expect(remote['user_weight']!.map((row) => row['user_id']), ['foreign']);
    expect(hive.userWeightBox.values, isEmpty);
    expect(
        requests
            .where((r) => r.method == 'DELETE')
            .single
            .url
            .queryParameters['user_id'],
        'eq.$owner');
  });

  test('legacy deletion of the last food sends zero totals', () async {
    legacy = true;
    await engine.intakes.addIntake(IntakeEntity(
        id: 'meal',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: IntakeForRecipeFixtures.chicken.meal!,
        dateTime: day));
    await engine.sync();
    expect(remote['tracked_days']?.single['caloriesTracked'], 165);
    await engine.intakes.deleteIntakeById('meal');
    await engine.sync();
    expect(remote['tracked_days']!.single['caloriesTracked'], 0);
  });

  test('legacy sync does not zero a remote history without its local journal',
      () async {
    legacy = true;
    await hive.trackedDayBox.put(
        '2026-11-03',
        TrackedDayDBO(
            day: day,
            calorieGoal: 2000,
            caloriesTracked: 0,
            updatedAt: DateTime.now().toUtc()));
    remote['tracked_days'] = [
      {
        'user_id': owner,
        'day': '2026-11-03',
        'calorieGoal': 2000,
        'caloriesTracked': 2240,
        'updated_at': stamp.toIso8601String()
      }
    ];
    await weights.addUserWeight(
        UserWeightDbo('00000000-0000-4000-8000-000000000099', 80, day, stamp));
    await engine.sync();
    expect(remote['user_weight']?.single['weight'], 80);
    expect(remote['tracked_days']!.single['caloriesTracked'], 2240);
  });

  for (final action in ['edit', 'delete', 'restart']) {
    test(
        'legacy server audit timestamp cannot erase pending $action during upload',
        () async {
      legacy = true;
      await weights.addUserWeight(UserWeightDbo(
          '00000000-0000-4000-8000-000000000099', 80, day, stamp));
      final entered = Completer<void>();
      final release = Completer<void>();
      beforeWrite = () async {
        beforeWrite = null;
        entered.complete();
        await release.future;
      };
      final running = engine.sync();
      await entered.future;
      if (action == 'delete') {
        await weights.deleteUserWeightByDate(day);
      } else {
        await weights.addUserWeight(UserWeightDbo(
            '00000000-0000-4000-8000-000000000099', 81, day, stamp));
      }
      final next = engine.sync();
      if (action == 'restart') await engine.stop();
      release.complete();
      await Future.wait([running, next]);
      if (action == 'restart') {
        engine = JournalSyncEngine(
            hive: hive,
            client: engine.client,
            config: engine.config,
            intakes: engine.intakes,
            recipes: engine.recipes,
            days: engine.days,
            weights: engine.weights,
            requestTimeout: const Duration(milliseconds: 100));
        await engine.sync();
      }
      if (action == 'delete') {
        expect(remote['user_weight'], isEmpty);
        expect(hive.userWeightBox.values, isEmpty);
      } else {
        expect(remote['user_weight']!.single['weight'], 81);
        expect(hive.userWeightBox.values.single.weight, 81);
      }
    });
  }
}
