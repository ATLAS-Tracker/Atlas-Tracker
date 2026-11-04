import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/coach_students_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class FakeAuth extends Mock implements GoTrueClient {}

class FakeClient extends Mock implements SupabaseClient {}

void main() {
  testWidgets(
      'last logged day ignores empty days, future days and other students',
      (tester) async {
    final http = MockSupabaseHttpClient();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logged = today.subtract(const Duration(days: 3));
    final transport = (await tester.runAsync(() async {
      final client =
          SupabaseClient('https://test.invalid', 'key', httpClient: http);
      await client.from('users').insert(
          {'id': 'student', 'coach_id': 'coach', 'display_name': 'Élève'});
      await client.from('tracked_days').insert([
        {
          'user_id': 'student',
          'day': DateFormat('yyyy-MM-dd').format(logged),
          'caloriesTracked': 1500
        },
        {
          'user_id': 'student',
          'day': DateFormat('yyyy-MM-dd').format(today),
          'caloriesTracked': 0
        },
        {
          'user_id': 'student',
          'day': DateFormat('yyyy-MM-dd')
              .format(today.add(const Duration(days: 1))),
          'caloriesTracked': 2000
        },
        {
          'user_id': 'foreign',
          'day': DateFormat('yyyy-MM-dd').format(today),
          'caloriesTracked': 2000
        },
      ]);
      return client;
    }))!;
    final auth = FakeAuth();
    when(() => auth.currentUser).thenReturn(User(
        id: 'coach',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01'));
    final client = FakeClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.from(any())).thenAnswer(
        (call) => transport.from(call.positionalArguments.single as String));
    locator.registerSingleton<SupabaseClient>(client);
    addTearDown(() async {
      await locator.reset();
      await tester.runAsync(transport.dispose);
      http.close();
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
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
        find.text(
            S.current.lastJournalDay(DateFormat.yMMMd('fr').format(logged))),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
