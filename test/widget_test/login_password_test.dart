import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/auth/login_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('login accepts existing passwords and sends their exact text',
      (tester) async {
    String? sentPassword;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/events'),
        (_) async => null);
    await Supabase.initialize(
        url: 'https://test.invalid',
        anonKey: 'test-key',
        debug: false,
        authOptions: FlutterAuthClientOptions(
            localStorage: const EmptyLocalStorage(),
            autoRefreshToken: false,
            detectSessionInUri: false),
        httpClient: MockClient((request) async {
          sentPassword = (jsonDecode(request.body)
              as Map<String, dynamic>)['password'] as String?;
          return http.Response('{"message":"Invalid login credentials"}', 400,
              headers: {'content-type': 'application/json'});
        }));
    addTearDown(() => Supabase.instance.dispose());
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: const LoginScreen()));
    await tester.pumpAndSettle();
    final password =
        tester.widget<TextFormField>(find.byType(TextFormField).last);
    expect(password.validator!(''), isNotNull);
    for (final value in ['abc', 'Abc123-_+', ' Abc123-_+ ']) {
      expect(password.validator!(value), isNull);
    }
    await tester.enterText(
        find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, ' Abc123-_+ ');
    await tester.tap(find.text(S.current.loginButton));
    await tester.pumpAndSettle();
    expect(sentPassword, ' Abc123-_+ ');
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
