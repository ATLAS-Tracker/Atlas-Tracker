import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/auth/validate_password.dart';
import 'package:opennutritracker/features/auth/password_rules_dialog.dart';
import 'package:opennutritracker/features/auth/password_utils.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _validMinLength = false;
  bool _validUppercase = false;
  bool _validLowercase = false;
  bool _validDigit = false;
  bool _validSpecial = false;
  bool _loading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final newPass = _passwordCtrl.text.trim();

    try {
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(S.of(context).resetPasswordChanged),
          content: Text(S.of(context).resetPasswordChanged),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationOptions.mainRoute,
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updatePasswordRules(String value) {
    setState(() {
      _validMinLength = PasswordUtils.hasMinLength(value);
      _validUppercase = PasswordUtils.hasUppercase(value);
      _validLowercase = PasswordUtils.hasLowercase(value);
      _validDigit = PasswordUtils.hasDigit(value);
      _validSpecial = PasswordUtils.hasSpecial(value);
    });
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).resetPasswordTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            Text(S.of(context).resetPasswordTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              S.of(context).resetPasswordNewLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // --- New password --- //
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscureNewPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _decoration(
                      S.of(context).resetPasswordNewLabel, Icons.lock_outline)
                  .copyWith(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_outlined),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => PasswordRulesDialog(
                          validMinLength: _validMinLength,
                          validUppercase: _validUppercase,
                          validLowercase: _validLowercase,
                          validDigit: _validDigit,
                          validSpecial: _validSpecial,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onChanged: _updatePasswordRules,
              validator: (value) => validatePassword(context, value),
            ),
            const SizedBox(height: 16),

            // --- Confirm --- //
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirmPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _decoration(S.of(context).resetPasswordConfirmLabel,
                      Icons.lock_outline)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) => (v != _passwordCtrl.text)
                  ? S.of(context).resetPasswordNoMatch
                  : null,
            ),
            const SizedBox(height: 32),

            // --- Button --- //
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(S.of(context).resetPasswordButton),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
