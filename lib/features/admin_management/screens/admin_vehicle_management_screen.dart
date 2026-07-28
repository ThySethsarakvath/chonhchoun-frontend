import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../branch_owner/widgets/branch_owner_content_widgets.dart';
import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../models/branch_model.dart';
import '../services/admin_vehicle_service.dart';
import '../services/branch_service.dart';

class AdminVehicleManagementScreen extends StatefulWidget {
  const AdminVehicleManagementScreen({super.key});

  @override
  State<AdminVehicleManagementScreen> createState() =>
      _AdminVehicleManagementScreenState();
}

class _AdminVehicleManagementScreenState
    extends State<AdminVehicleManagementScreen> {
  final _vehicleService = AdminVehicleService();
  final _branchService = BranchService();

  bool _loading = true;
  String? _error;
  List<Branch> _branches = const [];
  List<ManagedVehicle> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int get _availableVehicles => _vehicles
      .where((vehicle) => vehicle.isActive && vehicle.status == 'AVAILABLE')
      .length;

  int get _unassignedVehicles =>
      _vehicles.where((vehicle) => vehicle.branchId == null).length;

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _branchService.getAllBranches(),
        _vehicleService.getVehicles(),
      ]);

      if (!mounted) return;
      setState(() {
        _branches = results[0] as List<Branch>;
        _vehicles = results[1] as List<ManagedVehicle>;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showCreateVehicleDialog() async {
    final codeCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final warehouseCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final volumeCtrl = TextEditingController();
    final packageCtrl = TextEditingController();
    String vehicleType = driverTruckType;
    String? branchId;

    void applyDefaults() {
      final preset = vehicleCapacityPresetFor(vehicleType);
      weightCtrl.text = preset?.maxWeightKg?.toStringAsFixed(0) ?? '';
      packageCtrl.text = preset?.maxPackageCount?.toString() ?? '';
    }

    applyDefaults();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Company Vehicle'),
          content: SizedBox(
            width: 430,
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
                      if (value == null) return;
                      setDialogState(() {
                        vehicleType = value;
                        applyDefaults();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: branchId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to branch',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No branch yet'),
                      ),
                      ..._branches.map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch.id,
                          child: Text(branch.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => branchId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Plate number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: warehouseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Current warehouse',
                    ),
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
                    controller: volumeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Volume m3'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: packageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Package count'),
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
                try {
                  await _vehicleService.createVehicle(
                    code: codeCtrl.text.trim(),
                    vehicleType: vehicleType,
                    branchId: branchId,
                    plateNumber: plateCtrl.text.trim(),
                    currentWarehouse: warehouseCtrl.text.trim(),
                    maxWeightKg: double.tryParse(weightCtrl.text.trim()),
                    maxVolumeM3: double.tryParse(volumeCtrl.text.trim()),
                    maxPackageCount: int.tryParse(packageCtrl.text.trim()),
                  );
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company vehicle created successfully.'),
                    ),
                  );
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: const Color(0xFFD32F2F),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditVehicleDialog(ManagedVehicle vehicle) async {
    final plateCtrl = TextEditingController(text: vehicle.plateNumber ?? '');
    final warehouseCtrl =
        TextEditingController(text: vehicle.currentWarehouse ?? '');
    final weightCtrl =
        TextEditingController(text: vehicle.maxWeightKg?.toString() ?? '');
    final volumeCtrl =
        TextEditingController(text: vehicle.maxVolumeM3?.toString() ?? '');
    final packageCtrl =
        TextEditingController(text: vehicle.maxPackageCount?.toString() ?? '');
    String? branchId = vehicle.branchId;
    String status = vehicle.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${vehicle.code}'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: branchId,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No branch yet'),
                      ),
                      ..._branches.map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch.id,
                          child: Text(branch.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => branchId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Plate number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: warehouseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Current warehouse',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => status = value);
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
                    controller: volumeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Volume m3'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: packageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Package count'),
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
                try {
                  await _vehicleService.updateVehicle(
                    vehicle.id,
                    branchId: branchId,
                    plateNumber: plateCtrl.text.trim(),
                    currentWarehouse: warehouseCtrl.text.trim(),
                    status: status,
                    maxWeightKg: double.tryParse(weightCtrl.text.trim()),
                    maxVolumeM3: double.tryParse(volumeCtrl.text.trim()),
                    maxPackageCount: int.tryParse(packageCtrl.text.trim()),
                  );
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadData();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: const Color(0xFFD32F2F),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVehicleActivation(ManagedVehicle vehicle) async {
    try {
      if (vehicle.isActive) {
        await _vehicleService.deactivateVehicle(vehicle.id);
      } else {
        await _vehicleService.activateVehicle(vehicle.id);
      }
      await _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading company vehicles...',
      );
    }

    if (_error != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load vehicle management',
        description: _error!,
        actionLabel: 'Try again',
        onAction: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BranchOwnerSectionHero(
            title: 'Admin Vehicle Management',
            description:
                'Admin controls company vehicles here. Driver requests are now handled in their own separate admin feature, while this page stays focused on vehicle operations only.',
            icon: Icons.local_shipping_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _showCreateVehicleDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Company Vehicle'),
              ),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              BranchOwnerStatCard(
                label: 'Available Vehicles',
                value: '$_availableVehicles',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF15803D),
              ),
              BranchOwnerStatCard(
                label: 'Unassigned Vehicles',
                value: '$_unassignedVehicles',
                icon: Icons.move_to_inbox_rounded,
                color: const Color(0xFF7C3AED),
              ),
              BranchOwnerStatCard(
                label: 'Total Company Vehicles',
                value: '${_vehicles.length}',
                icon: Icons.directions_bus_filled_rounded,
                color: const Color(0xFF1D4ED8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BranchOwnerFeatureListCard(
            title: 'Vehicle management flow',
            items: const [
              '1. Admin creates and assigns company vehicles from this page.',
              '2. Branch owners operate only the vehicles assigned to their branch.',
              '3. Driver applications and approval requests are reviewed from the separate Driver Requests page.',
              'Branch owners cannot create company vehicles from their portal anymore.',
            ],
          ),
          const SizedBox(height: 20),
          const BranchOwnerSectionCard(
            title: 'Company Vehicles',
            description:
                'Create, assign, activate, deactivate, and update all company vehicles here. This keeps vehicle management in one clear admin place.',
          ),
          const SizedBox(height: 14),
          if (_vehicles.isEmpty)
            const BranchOwnerMessageCard(
              title: 'No company vehicles yet',
              description:
                  'Create the first company vehicle and optionally assign it to a branch.',
            )
          else
            ..._vehicles.map(
              (vehicle) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _VehicleCard(
                  vehicle: vehicle,
                  onEdit: () => _showEditVehicleDialog(vehicle),
                  onToggleStatus: () => _toggleVehicleActivation(vehicle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final ManagedVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vehicleTypeLabel(vehicle.type),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              _VehicleStatusBadge(vehicle: vehicle),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailChip(
                label: 'Branch: ${vehicle.branchName ?? 'No branch assigned'}',
              ),
              if (vehicle.branchCode?.isNotEmpty == true)
                _DetailChip(label: 'Code: ${vehicle.branchCode!}'),
              _DetailChip(label: 'Plate: ${vehicle.plateNumber ?? '-'}'),
              _DetailChip(
                label: 'Warehouse: ${vehicle.currentWarehouse ?? '-'}',
              ),
              if (vehicle.maxWeightKg != null)
                _DetailChip(label: 'Capacity: ${vehicle.maxWeightKg} kg'),
              if (vehicle.maxPackageCount != null)
                _DetailChip(label: 'Packages: ${vehicle.maxPackageCount}'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Vehicle'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(
                  vehicle.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                ),
                label: Text(vehicle.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  final ManagedVehicle vehicle;

  const _VehicleStatusBadge({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    if (!vehicle.isActive) {
      return const _StatusPill(
        label: 'Inactive',
        foreground: Color(0xFF991B1B),
        background: Color(0xFFFEE2E2),
      );
    }

    switch (vehicle.status) {
      case 'AVAILABLE':
        return const _StatusPill(
          label: 'Available',
          foreground: Color(0xFF166534),
          background: Color(0xFFDCFCE7),
        );
      case 'IN_USE':
        return const _StatusPill(
          label: 'In Use',
          foreground: Color(0xFF1D4ED8),
          background: Color(0xFFDBEAFE),
        );
      case 'MAINTENANCE':
        return const _StatusPill(
          label: 'Maintenance',
          foreground: Color(0xFF92400E),
          background: Color(0xFFFEF3C7),
        );
      default:
        return _StatusPill(
          label: vehicle.status,
          foreground: const Color(0xFF475569),
          background: const Color(0xFFE2E8F0),
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _DetailChip extends StatelessWidget {
  final String label;

  const _DetailChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
