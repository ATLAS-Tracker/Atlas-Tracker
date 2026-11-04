import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/generated/l10n.dart';

String authErrorMessage(BuildContext context, Object error) {
  final s = S.of(context);
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (error.statusCode == '429' || message.contains('rate limit')) {
      return s.authRateLimit;
    }
    if (message.contains('invalid login credentials')) {
      return s.loginInvalidCredentials;
    }
    if (message.contains('otp') || message.contains('token')) {
      return s.resetCodeInvalid;
    }
  }
  return s.authRetryError;
}
