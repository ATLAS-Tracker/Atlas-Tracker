import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/sync/profile_remote_sync.dart';

class FakeAuth extends Mock implements GoTrueClient {}

class FakeClient extends Mock implements SupabaseClient {}

class FakeGetUser extends Mock implements GetUserUsecase {}

class FakeAddUser extends Mock implements AddUserUsecase {}

void main() {
  test('offline profile edit survives pull and is retried before remote read',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('atlas_profile_queue_');
    Hive.init(directory.path);
    final hive = HiveDBProvider(userId: 'owner');
    hive.syncMetadataBox = await Hive.openBox<String>('metadata');
    locator.registerSingleton<HiveDBProvider>(hive);
    final user = UserEntity(
        name: 'Élève',
        birthday: DateTime(2000),
        heightCM: 180,
        weightKG: 82,
        gender: UserGenderEntity.male,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: UserPALEntity.active,
        role: UserRoleEntity.student);
    final getUser = FakeGetUser();
    when(() => getUser.hasUserData()).thenAnswer((_) async => true);
    when(() => getUser.getUserData()).thenAnswer((_) async => user);
    locator.registerSingleton<GetUserUsecase>(getUser);
    final addUser = FakeAddUser();
    registerFallbackValue(user);
    when(() => addUser.addUser(any())).thenAnswer((_) async {});
    locator.registerSingleton<AddUserUsecase>(addUser);
    var offline = true;
    final methods = <String>[];
    Map<String, dynamic>? sent;
    final transport = SupabaseClient('https://test.invalid', 'key',
        httpClient: MockClient((request) async {
      methods.add(request.method);
      if (offline) {
        return http.Response('{"message":"offline fixture"}', 400,
            request: request, headers: {'content-type': 'application/json'});
      }
      if (request.method == 'PATCH') {
        sent = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return http.Response('', 204, request: request);
      }
      return http.Response(
          jsonEncode([
            {'weight_kg': sent?['weight_kg'] ?? 70}
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json'});
    }));
    final auth = FakeAuth();
    when(() => auth.currentUser).thenReturn(User(
        id: 'owner',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01'));
    final client = FakeClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.from(any())).thenAnswer(
        (call) => transport.from(call.positionalArguments.single as String));
    addTearDown(() async {
      await locator.reset();
      await transport.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });
    await pushProfileToSupabase(client, user);
    expect(hive.syncMetadataBox!.get('profile_pending'), isNotNull);
    expect(SyncMetadata(hive.syncMetadataBox).deletions, isEmpty);
    expect(await syncProfileFromSupabase(client), isFalse);
    verifyNever(() => addUser.addUser(any()));
    offline = false;
    methods.clear();
    expect(await syncProfileFromSupabase(client), isTrue);
    expect(methods, ['PATCH', 'GET']);
    expect(sent!['weight_kg'], 82);
    expect(sent!.containsKey('role'), isFalse);
    expect(hive.syncMetadataBox!.get('profile_pending'), isNull);
    expect(verify(() => addUser.addUser(captureAny())).captured.single.weightKG,
        82);
  });
}
