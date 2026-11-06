import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/coach_students_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class FakeAuth extends Mock implements GoTrueClient {}

class FakeClient extends Mock implements SupabaseClient {}

class FakeRealtime extends Mock implements RealtimeClient {}

void main() {
  for (final largeHistory in [false, true]) {
    testWidgets(
        'last logged day uses grouped pages, largeHistory=$largeHistory',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final logged = today.subtract(const Duration(days: 3));
      final secondLogged =
          largeHistory ? today.subtract(const Duration(days: 700)) : today;
      String key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
      final history = [
        {'user_id': 'student', 'day': key(logged), 'caloriesTracked': 1500},
        if (largeHistory)
          for (var i = 1; i <= 500; i++)
            {
              'user_id': 'student',
              'day': key(logged.subtract(Duration(days: i))),
              'caloriesTracked': 1500
            },
        {
          'user_id': 'second',
          'day': key(secondLogged),
          'caloriesTracked': 1900
        },
        {'user_id': 'student', 'day': key(today), 'caloriesTracked': 0},
        {
          'user_id': 'student',
          'day': key(today.add(const Duration(days: 1))),
          'caloriesTracked': 2000
        },
        {'user_id': 'foreign', 'day': key(today), 'caloriesTracked': 2000},
      ];
      var groupedRequests = 0;
      final httpClient = MockClient((request) async {
        final query = request.url.queryParameters;
        Object rows;
        if (request.url.path.endsWith('/users')) {
          expect(query['coach_id'], 'eq.coach');
          rows = [
            {'id': 'second', 'display_name': 'Autre élève'},
            {'id': 'empty', 'display_name': 'Sans journal'},
            {'id': 'student', 'display_name': 'Élève'},
          ];
        } else {
          expect(request.url.path, endsWith('/tracked_days'));
          expect(query['user_id'], 'in.("second","empty","student")');
          if (query['select'] == 'user_id,day') {
            groupedRequests++;
            expect(query['caloriesTracked'], 'gt.0');
            expect(query['day'], 'lte.${key(today)}');
            expect(query['order'], startsWith('day.desc'));
            expect(query['order'], contains(',user_id.asc'));
            final eligible = history
                .where((row) =>
                    row['user_id'] != 'foreign' &&
                    (row['caloriesTracked'] as int) > 0 &&
                    (row['day'] as String).compareTo(key(today)) <= 0)
                .toList()
              ..sort(
                  (a, b) => (b['day'] as String).compareTo(a['day'] as String));
            final offset = int.parse(query['offset'] ?? '0');
            final limit = int.parse(query['limit']!);
            rows = eligible.skip(offset).take(limit).toList();
          } else {
            expect(query['day'], 'eq.${key(today)}');
            rows = history
                .where((row) =>
                    row['user_id'] != 'foreign' && row['day'] == key(today))
                .toList();
          }
        }
        return http.Response(jsonEncode(rows), 200,
            request: request, headers: {'content-type': 'application/json'});
      });
      final auth = FakeAuth();
      when(() => auth.currentUser).thenReturn(User(
          id: 'coach',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01'));
      final client = FakeClient();
      when(() => client.auth).thenReturn(auth);
      final realtime = FakeRealtime();
      when(() => client.from(any())).thenAnswer((call) {
        final table = call.positionalArguments.single as String;
        return SupabaseQueryBuilder(
            'https://test.invalid/rest/v1/$table', realtime,
            headers: <String, String>{},
            schema: 'public',
            table: table,
            httpClient: httpClient,
            incrementId: 0,
            isolate: null);
      });
      locator.registerSingleton<SupabaseClient>(client);
      addTearDown(() async {
        await locator.reset();
        httpClient.close();
      });
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          home: const CoachStudentsPage()));
      final future = tester
          .widget<FutureBuilder<List<Map<String, dynamic>>>>(
              find.byType(FutureBuilder<List<Map<String, dynamic>>>))
          .future!;
      await tester.runAsync(() => future);
      await tester.pumpAndSettle();
      expect(
          find.text(
              S.current.lastJournalDay(DateFormat.yMMMd('fr').format(logged))),
          findsOneWidget);
      expect(
          find.text(S.current
              .lastJournalDay(DateFormat.yMMMd('fr').format(secondLogged))),
          findsOneWidget);
      expect(groupedRequests, largeHistory ? 2 : 1);
      verify(() => client.from('tracked_days')).called(largeHistory ? 3 : 2);
      expect(tester.takeException(), isNull);
    });
  }
}
