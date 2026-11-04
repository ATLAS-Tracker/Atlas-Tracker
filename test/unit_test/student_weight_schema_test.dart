import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/student_macros_bloc.dart';

void main() {
  for (final modern in [false, true]) {
    test(
        'coach weights load against deployed schema and hide tombstones: modern=$modern',
        () async {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 1)));
      final client = SupabaseClient('https://test.invalid', 'key',
          httpClient: MockClient((request) async {
        final isWeight = request.url.pathSegments.last == 'user_weight';
        if (!modern && request.url.queryParameters.containsKey('deleted_at')) {
          return http.Response(
              '{"code":"42703","message":"column deleted_at does not exist"}',
              400,
              request: request,
              headers: {'content-type': 'application/json'});
        }
        final rows = isWeight
            ? [
                {'user_id': 'student', 'date': today, 'weight': 80},
                if (modern)
                  {
                    'user_id': 'student',
                    'date': yesterday,
                    'weight': 0,
                    'deleted_at': now.toIso8601String()
                  },
              ]
            : [];
        return http.Response(jsonEncode(rows), 200,
            request: request, headers: {'content-type': 'application/json'});
      }));
      final bloc = StudentMacrosBloc(client);
      addTearDown(() async {
        await bloc.close();
        await client.dispose();
      });
      final done = Completer<void>();
      bloc.add(LoadStudentMacrosEvent('student', done: done));
      await done.future;
      expect(bloc.state, isA<StudentMacrosLoaded>());
      final loaded = bloc.state as StudentMacrosLoaded;
      expect(loaded.macros[today]?['weight'], 80);
      expect(loaded.macros.containsKey(yesterday), isFalse);
    });
  }
}
