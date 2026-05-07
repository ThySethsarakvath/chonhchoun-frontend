import 'package:flutter/material.dart';

import '../../../widgets/driver_auth_widgets.dart';

class VehicleSelector extends StatelessWidget {
  const VehicleSelector({
    super.key,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  final String selectedVehicle;
  final ValueChanged<String> onVehicleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DriverVehicleOptionCard(
                label: 'Motorbike',
                icon: Icons.two_wheeler_rounded,
                isSelected: selectedVehicle == 'Motorbike',
                onTap: () => onVehicleSelected('Motorbike'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DriverVehicleOptionCard(
                label: 'Car',
                icon: Icons.directions_car_rounded,
                isSelected: selectedVehicle == 'Car',
                onTap: () => onVehicleSelected('Car'),
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
                isSelected: selectedVehicle == 'TukTuk',
                onTap: () => onVehicleSelected('TukTuk'),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
