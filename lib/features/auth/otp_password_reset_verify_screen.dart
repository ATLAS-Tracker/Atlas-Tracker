import 'package:flutter/material.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.trim().isEmpty) return;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                labelText: 'OTP code',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
