import 'package:flutter/material.dart';

import '../driver_workspace_screen.dart';
import '../widgets/driver_auth_widgets.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_shell_widgets.dart';
import 'driver_signup_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverAuthScaffold(
      heroChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverBackChip(onTap: () => Navigator.of(context).maybePop()),
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
            'Use the driver flow only. Customer pages stay untouched.',
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
            'Sign in',
            style: TextStyle(
              color: DriverColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Access requests, map details, and the driver dashboard.',
            style: TextStyle(
              color: DriverColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          DriverInputField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
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
                color: DriverColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DriverPrimaryButton(
              label: 'Continue as Driver',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const DriverWorkspaceScreen(),
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DriverOutlineButton(
              label: 'Create Driver Account',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const DriverSignupScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account yet?",
                style: TextStyle(color: DriverColors.muted),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const DriverSignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: DriverColors.blue,
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
