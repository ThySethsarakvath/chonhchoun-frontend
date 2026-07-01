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

class VehicleCapacityPreset {
  final double? maxWeightKg;
  final int? maxPackageCount;
  final String sourceLabel;

  const VehicleCapacityPreset({
    required this.maxWeightKg,
    required this.maxPackageCount,
    required this.sourceLabel,
  });
}

const String driverOwnMotorcycleType = 'MOTORCYCLE';
const String driverTruckType = 'TRUCK';
const String driverLargeTruckType = 'TRUCK_LARGE';
const String driverBranchTruckChoice = 'BRANCH_TRUCK';

const List<VehicleTypeOption> vehicleTypeOptions = [
  VehicleTypeOption(
    value: driverOwnMotorcycleType,
    label: 'Motorcycle',
    icon: Icons.two_wheeler_rounded,
  ),
  VehicleTypeOption(
    value: driverTruckType,
    label: 'Truck',
    icon: Icons.local_shipping_rounded,
  ),
  VehicleTypeOption(
    value: driverLargeTruckType,
    label: 'Large Truck',
    icon: Icons.fire_truck_rounded,
  ),
];

const List<VehicleTypeOption> ownVehicleTypeOptions = vehicleTypeOptions;

const List<VehicleTypeOption> branchVehicleTypeOptions = [
  VehicleTypeOption(
    value: driverTruckType,
    label: 'Truck',
    icon: Icons.local_shipping_rounded,
  ),
  VehicleTypeOption(
    value: driverLargeTruckType,
    label: 'Large Truck',
    icon: Icons.fire_truck_rounded,
  ),
];

const Map<String, VehicleCapacityPreset> vehicleCapacityPresets = {
  driverTruckType: VehicleCapacityPreset(
    maxWeightKg: 1500,
    maxPackageCount: 60,
    sourceLabel: 'Light truck default',
  ),
  driverLargeTruckType: VehicleCapacityPreset(
    maxWeightKg: 3500,
    maxPackageCount: 120,
    sourceLabel: 'Medium truck default',
  ),
};

VehicleTypeOption? vehicleTypeOptionFor(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final option in vehicleTypeOptions) {
    if (option.value == value) return option;
  }
  return null;
}

String vehicleTypeLabel(String? value) {
  if (value == null || value.isEmpty) return 'Vehicle not assigned';
  return vehicleTypeOptionFor(value)?.label ?? 'Vehicle';
}

String reviewVehicleTypeLabel(String? value) {
  if (value == driverOwnMotorcycleType) return 'Own Motorcycle';
  if (value == driverTruckType) return 'Own Truck';
  if (value == driverLargeTruckType) return 'Own Large Truck';
  if (value == driverBranchTruckChoice) return 'Branch Vehicle';
  return vehicleTypeLabel(value);
}

String deliveryCategoryLabel(String? value) {
  if (value == driverOwnMotorcycleType) return 'City Express';
  if (value == driverTruckType || value == driverLargeTruckType) {
    return 'Warehouse Route';
  }
  return 'Unassigned';
}

String deliveryOperationLabel(String? value) {
  if (value == driverOwnMotorcycleType) return 'City express delivery';
  if (value == driverTruckType || value == driverLargeTruckType) {
    return 'Warehouse-to-warehouse province delivery';
  }
  return 'Delivery operation';
}

String deliveryRouteLabel(String? value) {
  if (value == driverOwnMotorcycleType) return 'Inside the city';
  if (value == driverTruckType || value == driverLargeTruckType) {
    return 'Branch warehouse to branch warehouse';
  }
  return 'Route not assigned';
}

IconData vehicleTypeIcon(String? value) {
  if (value == driverBranchTruckChoice) {
    return Icons.local_shipping_rounded;
  }
  return vehicleTypeOptionFor(value)?.icon ?? Icons.local_shipping_outlined;
}

VehicleCapacityPreset? vehicleCapacityPresetFor(String? value) {
  if (value == null || value.isEmpty || value == driverOwnMotorcycleType) {
    return null;
  }
  return vehicleCapacityPresets[value];
}
