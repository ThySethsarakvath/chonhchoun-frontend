import 'package:flutter/material.dart';

import '../../../widgets/driver_auth_widgets.dart';
import '../../../widgets/driver_button_widgets.dart';
import '../../../widgets/driver_colors.dart';
import 'driver_info_box.dart';
import 'vehicle_selector.dart';

class DriverSignupForm extends StatelessWidget {
  const DriverSignupForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.zoneController,
    required this.selectedVehicle,
    required this.loading,
    required this.onVehicleSelected,
    required this.onCreateAccount,
    required this.onLoginTap,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController zoneController;
  final String selectedVehicle;
  final bool loading;
  final ValueChanged<String> onVehicleSelected;
  final VoidCallback onCreateAccount;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create driver account',
          style: TextStyle(
            color: DriverColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your vehicle type and verify your email before entering the driver workspace.',
          style: TextStyle(
            color: DriverColors.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Vehicle type',
          style: TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        VehicleSelector(
          selectedVehicle: selectedVehicle,
          onVehicleSelected: onVehicleSelected,
        ),
        const SizedBox(height: 20),
        DriverInputField(
          controller: nameController,
          label: 'Full Name',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 16),
        DriverInputField(
          controller: emailController,
          label: 'Email',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        DriverInputField(
          controller: zoneController,
          label: 'Preferred Zone',
          icon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 18),
        DriverInfoBox(selectedVehicle: selectedVehicle),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: DriverPrimaryButton(
            label: loading ? 'Loading...' : 'Create Account',
            onPressed: onCreateAccount,
            padding: const EdgeInsets.symmetric(vertical: 18),
            borderRadius: 18,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: DriverOutlineButton(
            label: 'Already Have an Account',
            onPressed: onLoginTap,
          ),
        ),
      ],
    );
  }
}
