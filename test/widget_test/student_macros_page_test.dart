import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/student_macros_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // Vraie police de l'app : la police de test (carrés) exagère les largeurs.
  setUpAll(() async {
    await (FontLoader('Poppins')
          ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
          ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf')))
        .load();
  });

  testWidgets(
      'day weight card restores the reference difference and trend includes today',
      (tester) async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final previous = DateFormat('yyyy-MM-dd')
        .format(DateTime(now.year, now.month, now.day - 1));
    final http = MockSupabaseHttpClient();
    final client = (await tester.runAsync(() async {
      final c =
          SupabaseClient('https://mock.supabase.co', 'key', httpClient: http);
      await c.from('users').insert({'id': 'student', 'weight_kg': 80});
      await c
          .from('user_weight')
          .insert({'user_id': 'student', 'date': today, 'weight': 85.3});
      await c
          .from('user_weight')
          .insert({'user_id': 'student', 'date': previous, 'weight': 84.9});
      await c.from('tracked_days').insert({
        'user_id': 'student',
        'day': today,
        'calorieGoal': 2000,
        'caloriesTracked': 1500,
        'carbsGoal': 200,
        'carbsTracked': 300,
        'fatGoal': 70,
        'fatTracked': 50,
        'proteinGoal': 150,
        'proteinTracked': 120,
      });
      return c;
    }))!;
    locator.registerSingleton<SupabaseClient>(client);
    addTearDown(() async {
      await locator.unregister<SupabaseClient>();
      await tester.runAsync(client.dispose);
      http.close();
    });
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!),
      theme: ThemeData(textTheme: appTextTheme),
      home: const StudentMacrosPage(studentId: 'student', studentName: 'Léa'),
    ));
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text(S.current.trendVsGoal('+5,3 kg')), findsOneWidget);
    expect(find.text('+0,4 kg'), findsNothing);
    expect(find.textContaining('85,3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final macros = find.text(S.current.dayMacrosTitle);
    await tester.ensureVisible(macros);
    await tester.tap(macros);
    await tester.pumpAndSettle();
    expect(find.text('150 %'), findsOneWidget,
        reason: 'over-goal percent appears once in percent mode');

    await tester.tap(find.text(S.current.studentTrendTab));
    await tester.pumpAndSettle();
    expect(find.text(S.current.studentConsistencyLabel), findsOneWidget);
    expect(find.text('85,3 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Les valeurs du résumé sont toutes collées au bord droit.
    expect(find.text(S.current.trendDaysTracked(0, 7)), findsOneWidget);
  });
}
