import 'package:flutter/material.dart';

import '../../../../features/auth/models/auth_models.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../router/app_router.dart';
import '../../widgets/driver_auth_widgets.dart';
import 'widgets/driver_hero_section.dart';
import 'widgets/driver_signup_form.dart';

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
      if (mounted) {
        _showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        _showError('Cannot create driver account');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onVehicleSelected(String vehicle) {
    setState(() => _selectedVehicle = vehicle);
  }

  void _goBack() {
    if (!_loading) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DriverAuthScaffold(
      heroChild: DriverSignupHeroSection(
        onBackTap: _goBack,
      ),
      formChild: DriverSignupForm(
        nameController: _nameController,
        emailController: _emailController,
        zoneController: _zoneController,
        selectedVehicle: _selectedVehicle,
        loading: _loading,
        onVehicleSelected: _onVehicleSelected,
        onCreateAccount: _createAccount,
        onLoginTap: _goBack,
      ),
    );
  }
}
