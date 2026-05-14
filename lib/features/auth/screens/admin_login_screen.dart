import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _service = AuthService();
  bool _loading = false;

  Future<void> _handleAdminLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      showErrorDialog(context, 'សូមបំពេញព័ត៌មានឱ្យបានគ្រប់គ្រាន់');
      return;
    }

    setState(() => _loading = true);
    try {
      // Reusing your LoginRequest model and AuthService
      await _service.login(LoginRequest(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));
      
      if (mounted) {
        // Navigate to your Admin Dashboard (Update route name as needed)
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'ការភ្ជាប់ត្រូវបានបដិសេធ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      logoAlignment: LogoAlignment.center, // Typical for Admin Portals
      body: Column(
        children: [
          const Text(
            'គ្រប់គ្រង ERP - Admin',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 8),
          const Text('សូមចូលទៅកាន់ផ្ទាំងគ្រប់គ្រងរបស់អ្នក', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          
          AdminAuthInputField(
            controller: _emailCtrl,
            label: 'អុីម៉ែលអ្នកគ្រប់គ្រង',
            hint: 'admin@chonhchoun.com',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 20),
          
          AdminAuthInputField(
            controller: _passwordCtrl,
            label: 'លេខសម្ងាត់',
            hint: '••••••••',
            icon: Icons.lock_person_outlined,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          
          AuthButton(
            label: 'ចូលប្រព័ន្ធ',
            onPressed: _handleAdminLogin,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}