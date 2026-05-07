import 'package:flutter/material.dart';
import '../../../../app/router/app_router.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/auth_header.dart';

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

  static final _emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateLogin() {
    if (_emailCtrl.text.trim().isEmpty) return 'សូមបញ្ចូលអ៊ីម៉ែលរបស់អ្នក';
    if (!_emailReg.hasMatch(_emailCtrl.text.trim())) return 'អ៊ីម៉ែលមិនត្រឹមត្រូវ';
    if (_passwordCtrl.text.isEmpty) return 'សូមបញ្ចូលលេខសម្ងាត់';
    if (_passwordCtrl.text.length < 6) return 'លេខសម្ងាត់ត្រូវតែមានយ៉ាងតិច 6 តួអក្សរ';
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
      final res = await _service.login(
        LoginRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );

      if (!mounted) return;

      if (res.user.role == 'driver') {
        Navigator.pushReplacementNamed(context, AppRoutes.driver);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.customer);
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goForgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      showErrorDialog(context, 'សូមបញ្ចូលអ៊ីម៉ែលរបស់អ្នកជាមុនសិន');
      return;
    }

    if (!_emailReg.hasMatch(email)) {
      showErrorDialog(context, 'អ៊ីម៉ែលមិនត្រឹមត្រូវ');
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.forgotPassword(ForgotPasswordRequest(email: email));

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.validateEmail,
          arguments: ValidateEmailArgs(
            flow: AuthFlow.forgotPassword,
            email: email,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ');
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
          const Text(
            'ចូលគណនី',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2D3D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'សូមស្វាគមន៍មកកាន់ ChonhChoun។ ចូលគណនីដើម្បីបន្តការដឹកជញ្ជូនរបស់អ្នក។',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A8D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          AuthTextField(
            label: 'អ៊ីម៉ែល',
            placeholder: 'បញ្ចូលអ៊ីម៉ែលរបស់អ្នក',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          AuthTextField(
            label: 'លេខសម្ងាត់',
            placeholder: 'បញ្ចូលលេខសម្ងាត់របស់អ្នក',
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),

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

          AuthButton(
            label: 'ចូលគណនី',
            onPressed: _submit,
            loading: _loading,
          ),
          const SizedBox(height: 20),

          AuthLinkRow(
            prefix: 'មិនទាន់មានគណនីមែនទេ? ',
            linkText: 'បង្កើតគណនី',
            onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: _loading
                ? null
                : () {
                    Navigator.pushNamed(context, AppRoutes.driverLogin);
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE3EE)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFF2C5F8A),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ចង់ក្លាយជា Driver Agent?',
                    style: TextStyle(
                      color: Color(0xFF1E2D3D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ចូលទៅកាន់ផ្នែកអ្នកបើកបរ ដើម្បីទទួលការស្នើសុំដឹកជញ្ជូន។',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7A8D),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
