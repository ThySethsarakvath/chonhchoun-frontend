import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../router/app_router.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _service = AuthService();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  static final _emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');
  static final _phoneReg = RegExp(r'^(\+?855|0)[0-9]{8,9}$');

  String? _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) return 'សូមបញ្ចូលឈ្មោះរបស់អ្នក';
    if (name.length < 2) return 'ឈ្មោះត្រូវតែ 2 តួអក្សរ ឬ ច្រើនជាងនេះ';

    if (email.isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';
    if (!_emailReg.hasMatch(email)) return 'អ៊ីមែលមិនត្រឹមត្រូវ';

    if (phone.isEmpty) return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
    if (!_phoneReg.hasMatch(phone)) {
      return 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ (ទទួលស្គាល់តែលេខកម្ពុជាប៉ុណ្ណោះ)';
    }

    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      showErrorDialog(context, err);
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.initiateRegister(
        InitiateRegisterRequest(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.validateEmail,
          arguments: ValidateEmailArgs(
            flow: AuthFlow.register,
            email: _emailCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
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
          const Text(
            'បង្កើតគណនី',
            style: TextStyle(
              fontSize: 24,
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

          AuthTextField(
            label: 'ឈ្មោះ',
            placeholder: 'បញ្ចូលឈ្មោះរបស់អ្នក',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 16),

          AuthTextField(
            label: 'អ៊ីមែល',
            placeholder: 'បញ្ចូលអ៊ីមែល',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          AuthTextField(
            label: 'លេខទូរស័ព្ទ',
            placeholder: 'បញ្ចូលលេខទូរស័ពរបស់អ្នក',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              // Only digits and a leading +
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
          ),
          const SizedBox(height: 40),

          AuthButton(label: 'បន្ទាប់', onPressed: _submit, loading: _loading),
          const SizedBox(height: 20),

          AuthLinkRow(
            prefix: 'មានគណនីហើយឬ​? ',
            linkText: 'ចូលគណនី',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
