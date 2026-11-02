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

  testWidgets('day and trend tabs fit a small screen, weight vs target',
      (tester) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final http = MockSupabaseHttpClient();
    final client = (await tester.runAsync(() async {
      final c = SupabaseClient('https://mock.supabase.co', 'key',
          httpClient: http);
      await c.from('users').insert({'id': 'student', 'weight_kg': 80});
      await c.from('user_weight').insert(
          {'user_id': 'student', 'date': today, 'weight': 85.3});
      await c.from('tracked_days').insert({
        'user_id': 'student',
        'day': today,
        'calorieGoal': 2000,
        'caloriesTracked': 1500,
        'carbsGoal': 200,
        'carbsTracked': 150,
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
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text(S.current.trendVsGoal('+5,3 kg')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(S.current.studentTrendTab));
    await tester.pumpAndSettle();
    expect(find.text(S.current.studentConsistencyLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Les valeurs du résumé sont toutes collées au bord droit.
    final consistency = find.text(S.current.trendDaysTracked(1, 7));
    final avgKcal = find.textContaining(S.current.kcalLabel).first;
    expect(tester.getTopRight(consistency).dx,
        closeTo(tester.getTopRight(avgKcal).dx, 0.5));
  });
}
