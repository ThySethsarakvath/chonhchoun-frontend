import 'package:flutter/material.dart';

import '../../../widgets/driver_auth_widgets.dart';
import '../../../widgets/driver_shell_widgets.dart';

class DriverSignupHeroSection extends StatelessWidget {
  const DriverSignupHeroSection({
    super.key,
    required this.onBackTap,
  });

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DriverBackChip(onTap: onBackTap),
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
    );
  }
}
