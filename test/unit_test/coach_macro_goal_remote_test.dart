import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/profile/coach_macro_goal_remote.dart';

void main() {
  for (final failure in [null, 'PGRST202', '42501']) {
    test('coach goal uses deployed upsert only when RPC is absent: $failure',
        () async {
      final requests = <http.Request>[];
      final client = SupabaseClient('https://test.invalid', 'key',
          httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.contains('/rpc/') && failure != null) {
          return http.Response(
              jsonEncode({'code': failure, 'message': 'Fixture'}),
              failure == '42501' ? 403 : 404,
              request: request,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('', 204, request: request);
      }));
      addTearDown(client.dispose);
      final save = saveCoachMacroGoal(client,
          studentId: 'student',
          startDate: DateTime.now(),
          carbs: 250,
          fat: 60,
          protein: 115);
      if (failure == '42501') {
        await expectLater(save, throwsA(isA<PostgrestException>()));
        expect(requests, hasLength(1));
      } else {
        await save;
        expect(requests, hasLength(failure == null ? 1 : 2));
        if (failure != null) {
          expect(requests.last.url.pathSegments.last, 'coach_macro_goals');
          expect(requests.last.url.queryParameters['on_conflict'], 'user_id');
          expect(jsonDecode(requests.last.body),
              containsPair('calorie_goal', 2000));
        }
      }
    });
  }
  test('invalid goals never issue a network write', () async {
    var writes = 0;
    final client = SupabaseClient('https://test.invalid', 'key',
        httpClient: MockClient((request) async {
      writes++;
      return http.Response('', 204, request: request);
    }));
    addTearDown(client.dispose);
    await expectLater(
        saveCoachMacroGoal(client,
            studentId: 'student',
            startDate: DateTime.now(),
            carbs: 0,
            fat: 0,
            protein: 0),
        throwsArgumentError);
    expect(writes, 0);
  });
}
