import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'validate_password.dart';
import 'auth_error_message.dart';

class OtpPasswordResetNewPasswordScreen extends StatefulWidget {
  const OtpPasswordResetNewPasswordScreen({super.key});

  @override
  State<OtpPasswordResetNewPasswordScreen> createState() =>
      _OtpPasswordResetNewPasswordScreenState();
}

class _OtpPasswordResetNewPasswordScreenState
    extends State<OtpPasswordResetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final newPass = _passwordCtrl.text;
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPass));
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationOptions.loginRoute,
        (_) => false,
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
      appBar: AppBar(title: Text(S.of(context).resetPasswordTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: S.of(context).resetPasswordNewLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure1
                        ? S.of(context).showPasswordLabel
                        : S.of(context).hidePasswordLabel,
                    icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (value) => validatePassword(context, value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: S.of(context).resetPasswordConfirmLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure2
                        ? S.of(context).showPasswordLabel
                        : S.of(context).hidePasswordLabel,
                    icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                validator: (v) => v == _passwordCtrl.text
                    ? null
                    : S.of(context).resetPasswordNoMatch,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _reset,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(S.of(context).resetPasswordButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
