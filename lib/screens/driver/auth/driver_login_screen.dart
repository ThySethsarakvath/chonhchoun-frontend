import 'package:flutter/material.dart';

import '../../../features/auth/models/auth_models.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../../../shared/widgets/app_button_widgets.dart';
import '../../../shared/colors/app_colors.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _service = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validateLogin() {
    if (_emailController.text.trim().isEmpty) {
      return 'Please enter your email';
    }

    if (_passwordController.text.isEmpty) {
      return 'Please enter your password';
    }

    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  Future<void> _submit() async {
    final error = _validateLogin();

    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.driver);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        _showError('Cannot connect to server');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToSignup() {
    if (!_loading) {
      Navigator.pushNamed(context, AppRoutes.driverSignup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DriverAuthScaffold(
      heroChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            'Driver auth',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome back,\nready to deliver?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Use your driver account to access delivery requests, map details, and your dashboard.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DriverHeaderChip(
                icon: Icons.route_rounded,
                label: 'Live route view',
              ),
              DriverHeaderChip(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Balance tracking',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Image.asset(
              'assets/images/openingVehicle.png',
              height: 170,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      formChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver sign in',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the same email and password you registered with.',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          DriverInputField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DriverInputField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: _loading ? 'Loading...' : 'Continue as Driver',
              onPressed: () {
                if (!_loading) {
                  _submit();
                }
              },
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppOutlineButton(
              label: 'Create Driver Account',
              onPressed: _goToSignup,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account yet?",
                style: TextStyle(color: AppColors.muted),
              ),
              TextButton(
                onPressed: _loading ? null : _goToSignup,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}