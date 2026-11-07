import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/features/auth/otp_password_reset_email_screen.dart';
import 'package:opennutritracker/features/auth/otp_password_reset_verify_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('requesting a password code cannot create an account',
      (tester) async {
    Map<String, dynamic>? sent;
    await Supabase.initialize(
        url: 'https://test.invalid',
        anonKey: 'test-key',
        debug: false,
        authOptions: FlutterAuthClientOptions(
            localStorage: const EmptyLocalStorage(),
            authFlowType: AuthFlowType.implicit,
            autoRefreshToken: false,
            detectSessionInUri: false),
        httpClient: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200,
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
        home: const OtpPasswordResetEmailScreen()));
    await tester.enterText(find.byType(TextFormField), 'typo@example.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(sent!['create_user'], isFalse);
    expect(find.byType(OtpPasswordResetVerifyScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
