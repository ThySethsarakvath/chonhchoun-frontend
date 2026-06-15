import 'package:flutter/material.dart';

import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchDriverAgentsScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final BranchDriverManagementOverview? overview;
  final Future<void> Function() onRefresh;
  final Future<void> Function({
    required String code,
    required String vehicleType,
    String? plateNumber,
    double? maxWeightKg,
    int? maxPackageCount,
  }) onCreateVehicle;
  final Future<void> Function(
    ManagedVehicle vehicle, {
    String? plateNumber,
    String? status,
    double? maxWeightKg,
    int? maxPackageCount,
  }) onUpdateVehicle;
  final Future<void> Function(ManagedVehicle vehicle) onActivateVehicle;
  final Future<void> Function(ManagedVehicle vehicle) onDeactivateVehicle;
  final Future<void> Function(
    ManagedDriver driver, {
    required String availabilityStatus,
    String? licenseNumber,
    double? maxLoadWeightKg,
    int? maxPackageCount,
  }) onUpdateDriverManagement;
  final Future<void> Function(
    ManagedDriver driver,
    ManagedVehicle vehicle,
  ) onAssignVehicle;
  final Future<void> Function(ManagedDriver driver) onUnassignVehicle;
  final Future<void> Function(ManagedDriver driver) onDeactivateDriver;

  const BranchDriverAgentsScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.overview,
    required this.onRefresh,
    required this.onCreateVehicle,
    required this.onUpdateVehicle,
    required this.onActivateVehicle,
    required this.onDeactivateVehicle,
    required this.onUpdateDriverManagement,
    required this.onAssignVehicle,
    required this.onUnassignVehicle,
    required this.onDeactivateDriver,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading driver management...',
      );
    }

    if (error != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load driver management',
        description: error!,
        actionLabel: 'Try again',
        onAction: onRefresh,
      );
    }

    final data = overview;
    if (data == null) {
      return BranchOwnerMessageCard(
        title: 'Driver management is not ready',
        description: 'Refresh after driver and vehicle data becomes available.',
        actionLabel: 'Refresh',
        onAction: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            BranchOwnerStatCard(
              label: 'Drivers',
              value: '${data.summary.totalDrivers}',
              icon: Icons.groups_rounded,
              color: const Color(0xFF1D4ED8),
            ),
            BranchOwnerStatCard(
              label: 'Available',
              value: '${data.summary.availableDrivers}',
              icon: Icons.flash_on_rounded,
              color: const Color(0xFF15803D),
            ),
            BranchOwnerStatCard(
              label: 'City Express Riders',
              value: '${data.summary.ownVehicleDrivers}',
              icon: Icons.two_wheeler_rounded,
              color: const Color(0xFF0F766E),
            ),
            BranchOwnerStatCard(
              label: 'Branch Vehicles',
              value: '${data.summary.companyVehicles}',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DriverManagementTable(
          overview: data,
          onUpdateDriverManagement: onUpdateDriverManagement,
          onAssignVehicle: onAssignVehicle,
          onUnassignVehicle: onUnassignVehicle,
          onDeactivateDriver: onDeactivateDriver,
        ),
        const SizedBox(height: 18),
        _VehicleManagementTable(
          overview: data,
          onCreateVehicle: onCreateVehicle,
          onUpdateVehicle: onUpdateVehicle,
          onActivateVehicle: onActivateVehicle,
          onDeactivateVehicle: onDeactivateVehicle,
        ),
      ],
    );
  }
}

class _DriverManagementTable extends StatelessWidget {
  final BranchDriverManagementOverview overview;
  final Future<void> Function(
    ManagedDriver driver, {
    required String availabilityStatus,
    String? licenseNumber,
    double? maxLoadWeightKg,
    int? maxPackageCount,
  }) onUpdateDriverManagement;
  final Future<void> Function(
    ManagedDriver driver,
    ManagedVehicle vehicle,
  ) onAssignVehicle;
  final Future<void> Function(ManagedDriver driver) onUnassignVehicle;
  final Future<void> Function(ManagedDriver driver) onDeactivateDriver;

  const _DriverManagementTable({
    required this.overview,
    required this.onUpdateDriverManagement,
    required this.onAssignVehicle,
    required this.onUnassignVehicle,
    required this.onDeactivateDriver,
  });

  @override
  Widget build(BuildContext context) {
    final activeDrivers = overview.drivers.where((driver) => driver.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Driver Management',
          subtitle:
              'Manage City Express riders and Province Warehouse Route drivers in one place. Driver-owned motorcycles stay with their rider, while branch vehicles support branch-to-branch province operations.',
        ),
        const SizedBox(height: 12),
        if (activeDrivers.isEmpty)
          const BranchOwnerMessageCard(
            title: 'No active drivers',
            description: 'Approved active drivers will appear here.',
          )
        else
          _TableFrame(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: const Color(0xFFE2E8F0),
                    ),
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      dataRowMinHeight: 74,
                      dataRowMaxHeight: 74,
                      dividerThickness: 1,
                      headingRowHeight: 56,
                      headingRowColor:
                          const MaterialStatePropertyAll(Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: _TableHeading('Driver')),
                        DataColumn(label: _TableHeading('Operation')),
                        DataColumn(label: _TableHeading('Phone')),
                        DataColumn(label: _TableHeading('Vehicle Type')),
                        DataColumn(label: _TableHeading('Current Vehicle')),
                        DataColumn(label: _TableHeading('Status')),
                        DataColumn(label: _TableHeading('Email')),
                        DataColumn(label: _TableHeading('Actions')),
                      ],
                      rows: activeDrivers.map((driver) {
                        final isCityExpressDriver = _isCityExpressDriver(driver);
                        final assignedVehicle = driver.assignments.isNotEmpty
                            ? driver.assignments.first.vehicle
                            : null;
                        final currentVehicle = assignedVehicle != null
                            ? _driverCurrentVehicleLabel(assignedVehicle)
                            : driver.assignedVehicleCode ?? '-';
                        return DataRow(
                          cells: [
                            DataCell(
                              _PrimaryInfoCell(
                                title: driver.name,
                                subtitle: isCityExpressDriver
                                    ? 'City express rider'
                                    : 'Province warehouse route',
                                icon: Icons.person_rounded,
                              ),
                            ),
                            DataCell(
                              _SoftPill(
                                label: deliveryCategoryLabel(driver.vehicleType),
                                foreground: isCityExpressDriver
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF7C3AED),
                                background: isCityExpressDriver
                                    ? const Color(0xFFCCFBF1)
                                    : const Color(0xFFEDE9FE),
                              ),
                            ),
                            DataCell(_SecondaryTableText(driver.phone)),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SoftPill(
                                    label: vehicleTypeLabel(driver.vehicleType),
                                    foreground: const Color(0xFF1D4ED8),
                                    background: const Color(0xFFDBEAFE),
                                  ),
                                  const SizedBox(height: 6),
                                  _SecondaryTableText(
                                    deliveryRouteLabel(driver.vehicleType),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              _SoftPill(
                                label: currentVehicle,
                                foreground: currentVehicle == '-'
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF1E3A5F),
                                background: currentVehicle == '-'
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            DataCell(
                              _StatusPill(status: driver.availabilityStatus),
                            ),
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: _SecondaryTableText(driver.email),
                              ),
                            ),
                            DataCell(
                              _ActionButtons(
                                primaryLabel: 'Manage',
                                onPrimary: () =>
                                    _showManageDriverDialog(context, driver),
                                secondaryLabel: 'Remove',
                                onSecondary: () => onDeactivateDriver(driver),
                                secondaryIsDestructive: true,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showManageDriverDialog(
    BuildContext context,
    ManagedDriver driver,
  ) async {
    final currentAssignment =
        driver.assignments.isNotEmpty ? driver.assignments.first : null;
    final currentVehicle = currentAssignment?.vehicle;
    final isCityExpressDriver = _isCityExpressDriver(driver);
    final activeVehicleAssignments = <String, String>{};
    for (final managedDriver in overview.drivers.where((item) => item.isActive)) {
      for (final assignment in managedDriver.assignments) {
        final vehicleId = assignment.vehicle?.id;
        if (vehicleId != null && vehicleId.isNotEmpty) {
          activeVehicleAssignments[vehicleId] = managedDriver.id;
        }
      }
    }
    final assignedVehicleCodes = <String, String>{};
    for (final managedDriver in overview.drivers.where((item) => item.isActive)) {
      final code = managedDriver.assignedVehicleCode?.trim();
      if (code != null && code.isNotEmpty) {
        assignedVehicleCodes[code] = managedDriver.id;
      }
    }

    final availableVehicles = overview.vehicles.where((vehicle) {
      if (isCityExpressDriver) return false;
      if (!vehicle.isCompanyVehicle) return false;
      if (!vehicle.isActive) return false;
      if (vehicle.status != 'AVAILABLE') return false;
      final assignedDriverId = activeVehicleAssignments[vehicle.id];
      if (assignedDriverId != null && assignedDriverId != driver.id) {
        return false;
      }
      final assignedCodeDriverId = assignedVehicleCodes[vehicle.code];
      if (assignedCodeDriverId != null && assignedCodeDriverId != driver.id) {
        return false;
      }
      return true;
    }).toList();

    var selectedStatus = driver.availabilityStatus;
    String? selectedVehicleId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Manage ${driver.name}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _availabilityOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isCityExpressDriver)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City express setup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'This driver works in the city with their own motorcycle. Branch vehicle reassignment is locked in this portal.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF065F46),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedVehicleId,
                      decoration: const InputDecoration(labelText: 'Assign vehicle'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Keep current vehicle'),
                        ),
                        ...availableVehicles.map(
                          (vehicle) => DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.code} - ${vehicleTypeLabel(vehicle.type)}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedVehicleId = value),
                    ),
                  if (currentVehicle != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current assignment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_driverCurrentVehicleLabel(currentVehicle)} - ${vehicleTypeLabel(currentVehicle.type)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            deliveryCategoryLabel(currentVehicle.type),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (!isCityExpressDriver) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await onUnassignVehicle(driver);
                                  if (context.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB45309),
                                  side: const BorderSide(
                                    color: Color(0xFFFCD34D),
                                  ),
                                ),
                                child: const Text('Unassign current vehicle'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await onUpdateDriverManagement(
                  driver,
                  availabilityStatus: selectedStatus,
                );
                if (!isCityExpressDriver && selectedVehicleId != null) {
                  for (final vehicle in availableVehicles) {
                    if (vehicle.id == selectedVehicleId) {
                      await onAssignVehicle(driver, vehicle);
                      break;
                    }
                  }
                }
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleManagementTable extends StatelessWidget {
  final BranchDriverManagementOverview overview;
  final Future<void> Function({
    required String code,
    required String vehicleType,
    String? plateNumber,
    double? maxWeightKg,
    int? maxPackageCount,
  }) onCreateVehicle;
  final Future<void> Function(
    ManagedVehicle vehicle, {
    String? plateNumber,
    String? status,
    double? maxWeightKg,
    int? maxPackageCount,
  }) onUpdateVehicle;
  final Future<void> Function(ManagedVehicle vehicle) onActivateVehicle;
  final Future<void> Function(ManagedVehicle vehicle) onDeactivateVehicle;

  const _VehicleManagementTable({
    required this.overview,
    required this.onCreateVehicle,
    required this.onUpdateVehicle,
    required this.onActivateVehicle,
    required this.onDeactivateVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final vehicles = overview.vehicles
        .where((vehicle) => vehicle.isCompanyVehicle)
        .toList()
      ..sort((a, b) {
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        return a.code.compareTo(b.code);
      });
    final assignedDriverByVehicle = <String, String>{};
    for (final driver in overview.drivers.where((driver) => driver.isActive)) {
      for (final assignment in driver.assignments) {
        final vehicleId = assignment.vehicle?.id;
        if (vehicleId != null && vehicleId.isNotEmpty) {
          assignedDriverByVehicle[vehicleId] = driver.name;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Vehicle Management',
                subtitle:
                    'Add and update branch-owned vehicles for Province Warehouse Route work between branches and provinces.',
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: FilledButton.icon(
                onPressed: () => _showAddVehicleDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Vehicle'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vehicles.isEmpty)
          const BranchOwnerMessageCard(
            title: 'No vehicles yet',
            description: 'Add a branch vehicle to start managing assignments.',
          )
        else
          _TableFrame(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: const Color(0xFFE2E8F0),
                    ),
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      dataRowMinHeight: 74,
                      dataRowMaxHeight: 74,
                      dividerThickness: 1,
                      headingRowHeight: 56,
                      headingRowColor:
                          const MaterialStatePropertyAll(Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: _TableHeading('Code')),
                        DataColumn(label: _TableHeading('Type')),
                        DataColumn(label: _TableHeading('Plate')),
                        DataColumn(label: _TableHeading('Capacity')),
                        DataColumn(label: _TableHeading('Ownership')),
                        DataColumn(label: _TableHeading('Assigned Driver')),
                        DataColumn(label: _TableHeading('Status')),
                        DataColumn(label: _TableHeading('Actions')),
                      ],
                      rows: vehicles.map((vehicle) {
                        final assignedDriver = assignedDriverByVehicle[vehicle.id] ?? '-';
                        final isAssigned = assignedDriver != '-';
                        final vehicleStatus =
                            isAssigned && vehicle.isActive ? 'IN_USE' : vehicle.status;
                        return DataRow(
                          cells: [
                            DataCell(
                              _PrimaryInfoCell(
                                title: vehicle.code,
                                subtitle: vehicle.plateNumber?.isNotEmpty == true
                                    ? vehicle.plateNumber!
                                    : 'No plate assigned',
                                icon: Icons.local_shipping_rounded,
                              ),
                            ),
                            DataCell(
                              _SoftPill(
                                label: vehicleTypeLabel(vehicle.type),
                                foreground: const Color(0xFF6D28D9),
                                background: const Color(0xFFEDE9FE),
                              ),
                            ),
                            DataCell(
                              _SecondaryTableText(
                                vehicle.plateNumber?.isNotEmpty == true
                                    ? vehicle.plateNumber!
                                    : '-',
                              ),
                            ),
                            DataCell(
                              _CapacityCell(
                                weightKg: vehicle.maxWeightKg,
                                packageCount: vehicle.maxPackageCount,
                              ),
                            ),
                            DataCell(
                              _SoftPill(
                                label: vehicle.isCompanyVehicle
                                    ? 'Company'
                                    : 'Driver-owned',
                                foreground: const Color(0xFF0F766E),
                                background: const Color(0xFFCCFBF1),
                              ),
                            ),
                            DataCell(_SecondaryTableText(assignedDriver)),
                            DataCell(_StatusPill(status: vehicleStatus)),
                            DataCell(
                              _ActionButtons(
                                primaryLabel: 'Edit',
                                onPrimary: () =>
                                    _showEditVehicleDialog(
                                      context,
                                      vehicle,
                                      isAssigned: isAssigned,
                                    ),
                                secondaryLabel:
                                    vehicle.isActive ? 'Deactivate' : 'Activate',
                                onSecondary: () => vehicle.isActive
                                    ? onDeactivateVehicle(vehicle)
                                    : onActivateVehicle(vehicle),
                                secondaryIsDestructive: vehicle.isActive,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddVehicleDialog(BuildContext context) async {
    final codeCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final packageCtrl = TextEditingController();
    var vehicleType = driverTruckType;

    void applyDefaults() {
      final preset = vehicleCapacityPresetFor(vehicleType);
      weightCtrl.text = preset?.maxWeightKg?.toStringAsFixed(0) ?? '';
      packageCtrl.text = preset?.maxPackageCount?.toString() ?? '';
    }

    applyDefaults();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Vehicle'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Vehicle code'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: vehicleType,
                    decoration: const InputDecoration(labelText: 'Vehicle type'),
                    items: branchVehicleTypeOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          vehicleType = value;
                          applyDefaults();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Plate number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Capacity kg'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: packageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity packages'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      vehicleCapacityPresetFor(vehicleType)?.sourceLabel ??
                          'No preset default',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await onCreateVehicle(
        code: codeCtrl.text.trim(),
        vehicleType: vehicleType,
        plateNumber: plateCtrl.text.trim(),
        maxWeightKg: double.tryParse(weightCtrl.text.trim()),
        maxPackageCount: int.tryParse(packageCtrl.text.trim()),
      );
    }
  }

  Future<void> _showEditVehicleDialog(
    BuildContext context,
    ManagedVehicle vehicle,
    {
    required bool isAssigned,
  }) async {
    final plateCtrl = TextEditingController(text: vehicle.plateNumber ?? '');
    final weightCtrl = TextEditingController(
      text: vehicle.maxWeightKg?.toStringAsFixed(vehicle.maxWeightKg! % 1 == 0 ? 0 : 1) ?? '',
    );
    final packageCtrl = TextEditingController(
      text: vehicle.maxPackageCount?.toString() ?? '',
    );
    var status = isAssigned ? 'IN_USE' : vehicle.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${vehicle.code}'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Plate number'),
                  ),
                  const SizedBox(height: 12),
                  if (isAssigned)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'In use',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This vehicle is assigned to a driver. Unassign it first to change the status.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'AVAILABLE', child: Text('Available')),
                        DropdownMenuItem(
                          value: 'UNAVAILABLE',
                          child: Text('Unavailable'),
                        ),
                        DropdownMenuItem(
                          value: 'MAINTENANCE',
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => status = value);
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Capacity kg'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: packageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity packages'),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        final preset = vehicleCapacityPresetFor(vehicle.type);
                        setState(() {
                          weightCtrl.text =
                              preset?.maxWeightKg?.toStringAsFixed(0) ?? '';
                          packageCtrl.text =
                              preset?.maxPackageCount?.toString() ?? '';
                        });
                      },
                      child: const Text('Reset to default'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await onUpdateVehicle(
                  vehicle,
                  plateNumber: plateCtrl.text.trim(),
                  status: status,
                  maxWeightKg: double.tryParse(weightCtrl.text.trim()),
                  maxPackageCount: int.tryParse(packageCtrl.text.trim()),
                );
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _TableFrame extends StatelessWidget {
  final Widget child;

  const _TableFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  final String label;

  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Color(0xFF475569),
      ),
    );
  }
}

class _PrimaryInfoCell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PrimaryInfoCell({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1D4ED8),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryTableText extends StatelessWidget {
  final String value;

  const _SecondaryTableText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _SoftPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final config = switch (normalized) {
      'AVAILABLE' => (
          fg: const Color(0xFF166534),
          bg: const Color(0xFFDCFCE7),
        ),
      'IN_USE' || 'ON_TRIP' => (
          fg: const Color(0xFF1D4ED8),
          bg: const Color(0xFFDBEAFE),
        ),
      'MAINTENANCE' || 'ON_BREAK' => (
          fg: const Color(0xFFB45309),
          bg: const Color(0xFFFEF3C7),
        ),
      'UNAVAILABLE' => (
          fg: const Color(0xFF9A3412),
          bg: const Color(0xFFFFEDD5),
        ),
      'INACTIVE' => (
          fg: const Color(0xFF475569),
          bg: const Color(0xFFE2E8F0),
        ),
      _ => (
          fg: const Color(0xFF991B1B),
          bg: const Color(0xFFFEE2E2),
        ),
    };

    return _SoftPill(
      label: normalized.replaceAll('_', ' '),
      foreground: config.fg,
      background: config.bg,
    );
  }
}

class _CapacityCell extends StatelessWidget {
  final double? weightKg;
  final int? packageCount;

  const _CapacityCell({
    required this.weightKg,
    required this.packageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _capacityLabel(
        weightKg: weightKg,
        packageCount: packageCount,
      ),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final bool secondaryIsDestructive;

  const _ActionButtons({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.secondaryIsDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPrimary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                foregroundColor: const Color(0xFF1D4ED8),
              ),
              child: Text(primaryLabel),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: secondaryIsDestructive
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFE2E8F0),
                ),
                foregroundColor: secondaryIsDestructive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF334155),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

String _capacityLabel({
  required double? weightKg,
  required int? packageCount,
}) {
  final parts = <String>[];
  if (weightKg != null) {
    parts.add('${weightKg % 1 == 0 ? weightKg.toStringAsFixed(0) : weightKg.toStringAsFixed(1)} kg');
  }
  if (packageCount != null) {
    parts.add('$packageCount packages');
  }
  return parts.isEmpty ? '-' : parts.join(' / ');
}

String _driverCurrentVehicleLabel(ManagedVehicle vehicle) {
  if (vehicle.ownershipType == 'DRIVER_OWNED') {
    if (vehicle.plateNumber != null && vehicle.plateNumber!.trim().isNotEmpty) {
      return vehicle.plateNumber!.trim();
    }
    if (vehicle.type == driverOwnMotorcycleType) {
      return 'Own motorbike';
    }
    return 'Own vehicle';
  }
  return vehicle.code;
}

bool _isCityExpressDriver(ManagedDriver driver) {
  final currentVehicle =
      driver.assignments.isNotEmpty ? driver.assignments.first.vehicle : null;
  return currentVehicle != null &&
      currentVehicle.ownershipType == 'DRIVER_OWNED' &&
      currentVehicle.type == driverOwnMotorcycleType &&
      currentVehicle.ownerDriverId == driver.id;
}

const _availabilityOptions = [
  'AVAILABLE',
  'ON_TRIP',
  'ON_BREAK',
  'UNAVAILABLE',
  'OFFLINE',
];
