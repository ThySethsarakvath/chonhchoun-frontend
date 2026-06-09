import 'package:flutter/material.dart';

class VehicleTypeOption {
  final String value;
  final String label;
  final IconData icon;

  const VehicleTypeOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const String driverOwnMotorcycleType = 'MOTORCYCLE';
const String driverBranchTruckType = 'TRUCK';
const String driverBranchTruckChoice = 'BRANCH_TRUCK';

const List<VehicleTypeOption> vehicleTypeOptions = [
  VehicleTypeOption(
    value: driverOwnMotorcycleType,
    label: 'Motorcycle',
    icon: Icons.two_wheeler_rounded,
  ),
  VehicleTypeOption(
    value: driverBranchTruckType,
    label: 'Truck',
    icon: Icons.local_shipping_rounded,
  ),
];

const List<VehicleTypeOption> branchVehicleTypeOptions = vehicleTypeOptions;

VehicleTypeOption? vehicleTypeOptionFor(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == driverOwnMotorcycleType) {
    return vehicleTypeOptions.first;
  }
  return vehicleTypeOptions.last;
}

String vehicleTypeLabel(String? value) {
  if (value == null || value.isEmpty) return 'Vehicle not assigned';
  return vehicleTypeOptionFor(value)?.label ?? 'Truck';
}

String reviewVehicleTypeLabel(String? value) {
  if (value == driverOwnMotorcycleType) return 'Own Motorcycle';
  return vehicleTypeLabel(value);
}

IconData vehicleTypeIcon(String? value) {
  return vehicleTypeOptionFor(value)?.icon ?? Icons.local_shipping_outlined;
}
