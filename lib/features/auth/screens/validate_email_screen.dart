import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class ValidateEmailScreen extends StatelessWidget {
  final ValidateEmailArgs args;

  const ValidateEmailScreen({super.key, required this.args});

  void _next(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.otp,
      arguments: OtpArgs(
        flow: args.flow,
        email: args.email ?? '',
        name: args.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AuthHeaderWithBack(onBack: () => Navigator.pop(context)),
            AuthContentContainer(
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
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDE3EE)),
                    ),
                    child: Text(
                      args.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3A4E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Next button ─────────────────────────────────────────
                  AuthButton(label: 'បន្ទាប់', onPressed: () => _next(context)),
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
