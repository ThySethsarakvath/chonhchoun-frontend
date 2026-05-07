import 'package:flutter/material.dart';

import '../../../widgets/driver_colors.dart';

class DriverInfoBox extends StatelessWidget {
  const DriverInfoBox({
    super.key,
    required this.selectedVehicle,
  });

  final String selectedVehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DriverColors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: DriverColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selected vehicle: $selectedVehicle. After email OTP verification, you will set your password and enter the driver workspace.',
              style: const TextStyle(
                color: DriverColors.text,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
