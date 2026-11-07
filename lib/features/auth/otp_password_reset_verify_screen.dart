import 'package:flutter/material.dart';
import 'dart:async';
import 'package:opennutritracker/generated/l10n.dart';
import 'auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_password_reset_new_password_screen.dart';

class OtpPasswordResetVerifyScreen extends StatefulWidget {
  final String email;
  const OtpPasswordResetVerifyScreen({super.key, required this.email});

  @override
  State<OtpPasswordResetVerifyScreen> createState() =>
      _OtpPasswordResetVerifyScreenState();
}

class _OtpPasswordResetVerifyScreenState
    extends State<OtpPasswordResetVerifyScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _canResend = false;
  Timer? _resendTimer;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cooldown();
  }

  void _cooldown() {
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _canResend = true);
    });
  }

  Future<void> _resend() async {
    if (_loading || !_canResend) return;
    setState(() => _loading = true);
    try {
      await _supabase.auth
          .signInWithOtp(email: widget.email, shouldCreateUser: false);
      _cooldown();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).codeSentLabel)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authErrorMessage(context, error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_loading || _codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final token = _codeCtrl.text.trim();
    try {
      await _supabase.auth.verifyOTP(
        email: widget.email,
        token: token,
        type: OtpType.email,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OtpPasswordResetNewPasswordScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(context, e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).enterCodeLabel)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofillHints: const [AutofillHints.oneTimeCode],
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                labelText: S.of(context).enterCodeLabel,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(S.of(context).verifyCodeLabel),
              ),
            ),
            TextButton(
                onPressed: _canResend && !_loading ? _resend : null,
                child: Text(S.of(context).resendCodeLabel)),
            if (!_canResend) Text(S.of(context).codeCooldownHelp),
          ],
        ),
      ),
    );
  }
}
