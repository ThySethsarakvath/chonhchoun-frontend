import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class ValidateEmailScreen extends StatefulWidget {
  final ValidateEmailArgs args;

  const ValidateEmailScreen({super.key, required this.args});

  @override
  State<ValidateEmailScreen> createState() => _ValidateEmailScreenState();
}

class _ValidateEmailScreenState extends State<ValidateEmailScreen> {
  final _service = AuthService();
  bool _loading = false;

  // ── Submit — send OTP to the pre-filled email ─────────────────────────────

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (widget.args.flow == AuthFlow.forgotPassword) {
        // Forgot password: we need the email from user first
        // (handled by the email field below)
      }
      // OTP was already sent by register/initiate or will be sent by /forgot
      // Navigate directly to OTP screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.otp,
          arguments: OtpArgs(
            flow: widget.args.flow,
            email: widget.args.email ?? '',
            name: widget.args.name,
          ),
        );
      }
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មានបញ្ហាក្នុងការផ្ញើលេខកូដ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AuthHeaderWithBack(onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Title ──────────────────────────────────────────────
                  const Center(
                    child: Text(
                      'ផ្ទៀងផ្ទាត់គណនី',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2D3D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'សុវត្ថិភាព, ទំនុកចិត្ត និង រហ័ស',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7A8D)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Description ─────────────────────────────────────────
                  const Text(
                    'ដើម្បីទទួលបាននូវស្តង់ដារសុវត្ថិភាពខ្ពស់, ពួកយើងនឹងផ្ញើសារលេខកូដ ចំនួន 6 ខ្ទង់ទៅកាន់គណនី:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Email display box ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDE3EE)),
                    ),
                    child: Text(
                      widget.args.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3A4E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Next button ─────────────────────────────────────────
                  AuthButton(
                    label: 'បន្ទាប់',
                    onPressed: _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}