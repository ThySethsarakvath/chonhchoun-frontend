import 'package:flutter/material.dart';
import '../../../router/app_router.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class SetPasswordScreen extends StatefulWidget {
  final SetPasswordArgs args;

  const SetPasswordScreen({super.key, required this.args});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validate() {
    if (_passwordCtrl.text.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
    if (_passwordCtrl.text.length < 8) return 'ពាក្យសម្ងាត់ត្រូវតែ 8 តួអក្សរ ឬ ច្រើនជាងនេះ';
    if (_confirmCtrl.text.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់ម្តងទៀត';
    if (_passwordCtrl.text != _confirmCtrl.text) {
      return 'ពាក្យសម្ងាត់មិនដូចគ្នា';
    }
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
      if (widget.args.flow == AuthFlow.register) {
        // Complete registration → logged in
        await _service.completeRegister(CompleteRegisterRequest(
          setupToken: widget.args.setupToken!,
          password: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
        ));
      } else {
        // Reset password → back to login
        await _service.resetPassword(ResetPasswordRequest(
          resetToken: widget.args.resetToken!,
          newPassword: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
        ));
      }

      if (mounted) {
        if (widget.args.flow == AuthFlow.register) {
          // Auto-logged-in after register complete
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.customer, (_) => false);
        } else {
          // Forgot password done → back to login
          showSuccessSnack(context, 'ពាក្យសម្ងាត់ត្រូវបានកំណត់ឡើងវិញ');
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
        }
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចកំណត់ពាក្យសម្ងាត់បានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _buttonLabel =>
      widget.args.flow == AuthFlow.register ? 'បង្កើតគណនី' : 'កំណត់';

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // ── Title ─────────────────────────────────────────────
                  const Text(
                    'កំណត់ពាក្យសម្ងាត់',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2D3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'សុវត្ថិភាព, ទំនុកចិត្ត និង រហ័ស',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7A8D)),
                  ),
                  const SizedBox(height: 28),

                  // ── Password ───────────────────────────────────────────
                  AuthTextField(
                    label: 'ពាក្យសម្ងាត់',
                    placeholder: 'សូមបញ្ចូល ពាក្យសម្ងាត់',
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    showToggle: true,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm password ───────────────────────────────────
                  AuthTextField(
                    label: 'បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត',
                    placeholder: 'សូមបញ្ចូល  ពាក្យសម្ងាត់ ម្តងទៀត',
                    controller: _confirmCtrl,
                    obscure: _obscureConfirm,
                    showToggle: true,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 40),

                  // ── Submit button ──────────────────────────────────────
                  AuthButton(
                    label: _buttonLabel,
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