import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _service = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validate() {
    if (_identifierCtrl.text.trim().isEmpty) {
      return 'សូមបញ្ចូលអុីម៉ែល ឬ លេខទូរស័ព្ទ';
    }
    if (_passwordCtrl.text.isEmpty) return 'សូមបញ្ចូលលេខសម្ងាត់';
    if (_passwordCtrl.text.length < 6) return 'លេខសម្ងាត់ត្រូវតែ 6 តួអក្សរ ឬ ច្រើនជាងនេះ';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      showErrorDialog(context, err);
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.login(LoginRequest(
        email: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.customer);
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនបម្រើបានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Forgot password flow ──────────────────────────────────────────────────

  void _goForgotPassword() {
    Navigator.pushNamed(
      context,
      AppRoutes.validateEmail,
      arguments: const ValidateEmailArgs(flow: AuthFlow.forgotPassword),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      logoAlignment: LogoAlignment.left,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ───────────────────────────────────────────────────────
          const Text(
            'ចូលគណនី',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2D3D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'សូមស្វាគមន៍, អ្នកបានត្រឡប់មកវិញហើយ !!!',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7A8D)),
          ),
          const SizedBox(height: 28),

          // ── Email / phone ────────────────────────────────────────────────
          AuthTextField(
            label: 'អុីម៉ែល ឬ លេខទូរស័ព្ទ',
            placeholder: 'បញ្ចូលអុីម៉ែល ឬ លេខទូរស័ព្ទរបស់អ្នក',
            controller: _identifierCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────────────
          AuthTextField(
            label: 'លេខសម្ងាត់',
            placeholder: 'បញ្ចូលលេខសម្ងាត់របស់អ្នក',
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),

          // ── Forgot password link ─────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _goForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'ភ្លេចលេខសម្ងាត់?',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A8DDB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Login button ─────────────────────────────────────────────────
          AuthButton(
            label: 'ចូល',
            onPressed: _submit,
            loading: _loading,
          ),
          const SizedBox(height: 20),

          // ── Register link ────────────────────────────────────────────────
          AuthLinkRow(
            prefix: 'មិនទាន់មានគណនី​? ',
            linkText: 'បង្កើតគណនី',
            onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          ),
        ],
      ),
    );
  }
}