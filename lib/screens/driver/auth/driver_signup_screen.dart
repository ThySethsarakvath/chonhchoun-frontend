import 'package:flutter/material.dart';

import '../../../features/auth/services/auth_service.dart';
import '../driver_workspace_screen.dart';
import '../../../shared/widgets/driver_auth_widgets.dart';
import '../../../shared/widgets/driver_button_widgets.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import 'driver_login_screen.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController(
    text: 'Phnom Penh',
  );
  final _service = AuthService();
  String _selectedVehicle = 'MOTORCYCLE';
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.driverRegister({
        'name': _nameController.text.trim(),
        'email': 'driver_${DateTime.now().millisecondsSinceEpoch}@example.com', // dummy email for now since UI doesn't have it
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'vehicleType': _selectedVehicle,
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DriverWorkspaceScreen()),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            'Set up the vehicle, access request cards, and move into the new driver dashboard flow.',
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
                  subtitle: 'Motorbike or truck',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DriverFeatureTile(
                  icon: Icons.map_outlined,
                  title: 'Map Preview',
                  subtitle: 'Leaflet placeholder',
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
              color: DriverColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only the driver side is being redesigned here. Customer flow stays as-is.',
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
          Row(
            children: [
              Expanded(
                child: DriverVehicleOptionCard(
                  label: 'Motorbike',
                  icon: Icons.two_wheeler_rounded,
                  isSelected: _selectedVehicle == 'MOTORCYCLE',
                  onTap: () {
                    setState(() => _selectedVehicle = 'MOTORCYCLE');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DriverVehicleOptionCard(
                  label: 'Truck',
                  icon: Icons.local_shipping_rounded,
                  isSelected: _selectedVehicle == 'Truck',
                  onTap: () {
                    setState(() => _selectedVehicle = 'Truck');
                  },
                ),
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
              color: DriverColors.blue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: DriverColors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The next screen includes a bottom driver bar, request detail cards, and an OpenStreetMap placeholder map.',
                    style: TextStyle(
                      color: DriverColors.text,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : DriverPrimaryButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    borderRadius: 18,
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DriverOutlineButton(
              label: 'Already Have an Account',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const DriverLoginScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
