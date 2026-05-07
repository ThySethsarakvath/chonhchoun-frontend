import 'package:flutter/material.dart';

import '../../../features/auth/models/auth_models.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../../../shared/widgets/app_button_widgets.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _zoneController =
      TextEditingController(text: 'Phnom Penh');

  final AuthService _service = AuthService();

  String _selectedVehicle = 'Motorbike';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }

    if (_emailController.text.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');
    if (!emailReg.hasMatch(_emailController.text.trim())) {
      return 'Please enter a valid email';
    }

    return null;
  }

  Future<void> _createAccount() async {
    final error = _validate();

    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.initiateRegister(
        InitiateRegisterRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: 'driver',
        ),
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.validateEmail,
          arguments: ValidateEmailArgs(
            flow: AuthFlow.driverRegister,
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            redirectRoute: AppRoutes.driver,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Cannot create driver account');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DriverAuthScaffold(
      heroChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBackChip(onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 18),
          const Text(
            'Driver auth',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Become a driver\nand start earning.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set up your vehicle, verify your email, and move into the driver dashboard flow.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: DriverFeatureTile(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Vehicle Type',
                  subtitle: 'Motorbike, car, tuk-tuk',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DriverFeatureTile(
                  icon: Icons.verified_user_outlined,
                  title: 'OTP Verify',
                  subtitle: 'Email security',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Image.asset(
              'assets/images/openingVehicle.png',
              height: 156,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      formChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create driver account',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your vehicle type and verify your email before entering the driver workspace.',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Vehicle type',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DriverVehicleOptionCard(
                      label: 'Motorbike',
                      icon: Icons.two_wheeler_rounded,
                      isSelected: _selectedVehicle == 'Motorbike',
                      onTap: () {
                        setState(() => _selectedVehicle = 'Motorbike');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DriverVehicleOptionCard(
                      label: 'Car',
                      icon: Icons.directions_car_rounded,
                      isSelected: _selectedVehicle == 'Car',
                      onTap: () {
                        setState(() => _selectedVehicle = 'Car');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DriverVehicleOptionCard(
                      label: 'TukTuk',
                      icon: Icons.electric_rickshaw_rounded,
                      isSelected: _selectedVehicle == 'TukTuk',
                      onTap: () {
                        setState(() => _selectedVehicle = 'TukTuk');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          DriverInputField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          DriverInputField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DriverInputField(
            controller: _zoneController,
            label: 'Preferred Zone',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected vehicle: $_selectedVehicle. After email OTP verification, you will set your password and enter the driver workspace.',
                    style: const TextStyle(
                      color: AppColors.text,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: _loading ? 'Loading...' : 'Create Account',
              onPressed: () {
                if (!_loading) {
                  _createAccount();
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
              label: 'Already Have an Account',
              onPressed: () {
                if (!_loading) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}