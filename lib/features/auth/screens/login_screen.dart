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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _service = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }


  static final _emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');

  String? _validateLogin() {
    if (_emailCtrl.text.trim().isEmpty) return 'សូមបញ្ចូលអុីម៉ែលរបស់អ្នក';
    if (!_emailReg.hasMatch(_emailCtrl.text.trim())) return 'អុីម៉ែលមិនត្រឹមត្រូវ';
    if (_passwordCtrl.text.isEmpty) return 'សូមបញ្ចូលលេខសម្ងាត់';
    if (_passwordCtrl.text.length < 6) return 'លេខសម្ងាត់ត្រូវតែ 6 តួអក្សរ ឬ ច្រើនជាងនេះ';
    return null;
  }


  Future<void> _submit() async {
    final err = _validateLogin();
    if (err != null) {
      showErrorDialog(context, err);
      return;
    }

    setState(() => _loading = true);
    try {
      final authResponse = await _service.login(LoginRequest(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));

      if (mounted) {
        if (authResponse.user.role == 'admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.customer);
        }
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនបម្រើបានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  // ── Forgot password ───────────────────────────────────────────────────────
  // Requires a valid email first, calls /forgot to send OTP,
  // then navigates with the email so ValidateEmailScreen can display it.

  Future<void> _goForgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      showErrorDialog(context, 'សូមបញ្ចូលអុីម៉ែលរបស់អ្នកជាមុនសិន');
      return;
    }
    if (!_emailReg.hasMatch(email)) {
      showErrorDialog(context, 'អុីម៉ែលមិនត្រឹមត្រូវ');
      return;
    }

    setState(() => _loading = true);
    try {
      // Send OTP before leaving this screen
      await _service.forgotPassword(ForgotPasswordRequest(email: email));

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.validateEmail,
          arguments: ValidateEmailArgs(
            flow: AuthFlow.forgotPassword,
            email: email, // ← passed to ValidateEmailScreen to display
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនបម្រើបានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

          // ── Email ────────────────────────────────────────────────────────
          AuthTextField(
            label: 'អុីម៉ែល',
            placeholder: 'បញ្ចូលអុីម៉ែលរបស់អ្នក',
            controller: _emailCtrl,
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
              onPressed: _loading ? null : _goForgotPassword,
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