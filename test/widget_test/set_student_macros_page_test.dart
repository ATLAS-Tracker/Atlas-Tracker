import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/set_student_macros_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'macro editor fits small screens and updates energy, dark=$dark',
        (tester) async {
      final http = MockSupabaseHttpClient();
      final client = (await tester.runAsync(() async => SupabaseClient(
          'https://mock.supabase.co', 'key',
          httpClient: http)))!;
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
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!),
        home: const SetStudentMacrosPage(
            studentId: 'student',
            initialCarbs: 200,
            initialFat: 60,
            initialProtein: 150),
      ));
      await tester.pumpAndSettle();
      expect(find.text('1940 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField).first, '250');
      await tester.pumpAndSettle();
      expect(find.text('2140 kcal'), findsOneWidget);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final date = find.text(DateFormat.yMMMMd('fr').format(today));
      await tester.ensureVisible(date);
      await tester.pumpAndSettle();
      expect(date, findsOneWidget);
      expect(
          find.text(S.current.buttonSaveLabel).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<FilledButton>(find.ancestor(
                  of: find.text(S.current.buttonSaveLabel),
                  matching: find.byWidgetPredicate((w) => w is FilledButton)))
              .onPressed,
          isNull);
      await tester.tap(find.text(S.current.historyLabel));
      await tester.pumpAndSettle();
      expect(find.text(S.current.macroGoalHistoryEmpty), findsOneWidget);
    });
  }

  testWidgets(
      'history shows current and future goals without prefilling the future',
      (tester) async {
    final http = MockSupabaseHttpClient();
    final client = (await tester.runAsync(() async {
      final c =
          SupabaseClient('https://mock.supabase.co', 'key', httpClient: http);
      await c.from('coach_macro_goals').insert({
        'user_id': 'student',
        'start_date': '2026-10-01',
        'carb_goal': 180,
        'fat_goal': 70,
        'protein_goal': 160,
      });
      await c.from('coach_macro_goals').insert({
        'user_id': 'student',
        'start_date': DateFormat('yyyy-MM-dd')
            .format(DateTime.now().add(const Duration(days: 3))),
        'carb_goal': 300,
        'fat_goal': 70,
        'protein_goal': 150,
      });
      return c;
    }))!;
    locator.registerSingleton<SupabaseClient>(client);
    addTearDown(() async {
      await locator.unregister<SupabaseClient>();
      await tester.runAsync(client.dispose);
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
      home: const SetStudentMacrosPage(
          studentId: 'student',
          initialCarbs: 200,
          initialFat: 60,
          initialProtein: 150),
    ));
    await tester.runAsync(() => Future.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('1990 kcal'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '200');
    await tester.pumpAndSettle();
    expect(find.text(S.current.trendVsGoal('+80 kcal')), findsOneWidget);
    await tester.tap(find.text(S.current.historyLabel));
    await tester.pumpAndSettle();
    expect(find.text('1990 ${S.current.kcalLabel}'), findsOneWidget);
    expect(find.text('2430 ${S.current.kcalLabel}'), findsOneWidget);
    expect(find.text(S.current.macroGoalHistoryEmpty), findsNothing);
  });
}
