import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_password_reset_verify_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'auth_error_message.dart';

class OtpPasswordResetEmailScreen extends StatefulWidget {
  const OtpPasswordResetEmailScreen({super.key});

  @override
  State<OtpPasswordResetEmailScreen> createState() =>
      _OtpPasswordResetEmailScreenState();
}

class _OtpPasswordResetEmailScreenState
    extends State<OtpPasswordResetEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpPasswordResetVerifyScreen(email: email),
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
      appBar: AppBar(title: Text(S.of(context).loginForgotPassword)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: S.of(context).loginEmailLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? S.of(context).loginEmailRequired
                    : (EmailValidator.validate(v.trim())
                        ? null
                        : S.of(context).loginEmailInvalid),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(S.of(context).sendCodeLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
