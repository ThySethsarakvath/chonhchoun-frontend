import 'package:flutter/material.dart';

import '../../driver_registration/models/driver_application_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchDriverAgentsScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<BranchDriver> drivers;
  final Future<void> Function() onRefresh;
  final Future<void> Function(
    BranchDriver driver,
    String vehicleType,
    String? assignedVehicleCode,
  )
      onUpdateVehicleType;

  const BranchDriverAgentsScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.drivers,
    required this.onRefresh,
    required this.onUpdateVehicleType,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const BranchOwnerLoadingCard(
        message: 'កំពុងផ្ទុកអ្នកបើកបររបស់សាខា...',
      );
    }

    if (error != null) {
      return BranchOwnerMessageCard(
        title: 'មិនអាចផ្ទុកអ្នកបើកបរសាខាបានទេ',
        description: error!,
        actionLabel: 'ព្យាយាមម្តងទៀត',
        onAction: onRefresh,
      );
    }

    if (drivers.isEmpty) {
      return BranchOwnerMessageCard(
        title: 'មិនទាន់មានអ្នកបើកបរនៅឡើយទេ',
        description:
            'អ្នកបើកបរដែលបានអនុម័តនឹងបង្ហាញនៅទីនេះបន្ទាប់ពីពាក្យស្នើសុំត្រូវបានទទួលយក។',
        actionLabel: 'ផ្ទុកឡើងវិញ',
        onAction: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'អ្នកបើកបររបស់សាខា',
          description:
              'ខាងក្រោមនេះជាអ្នកបើកបរដែលត្រូវបានអនុម័តឱ្យធ្វើការក្រោមសាខារបស់អ្នក។',
        ),
        const SizedBox(height: 14),
        ...drivers.map(
          (driver) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DriverCard(
              driver: driver,
              onUpdateVehicleType: (vehicleType, assignedVehicleCode) =>
                  onUpdateVehicleType(
                    driver,
                    vehicleType,
                    assignedVehicleCode,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatefulWidget {
  final BranchDriver driver;
  final Future<void> Function(
    String vehicleType,
    String? assignedVehicleCode,
  )
      onUpdateVehicleType;

  const _DriverCard({
    required this.driver,
    required this.onUpdateVehicleType,
  });

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  final _truckCodeCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _truckCodeCtrl.text = widget.driver.assignedVehicleCode ?? '';
  }

  @override
  void dispose() {
    _truckCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final isMotorcycle = driver.vehicleType == driverOwnMotorcycleType;
    final truckCode = _truckCodeCtrl.text.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE0F2FE),
            backgroundImage:
                driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty
                    ? NetworkImage(driver.avatarUrl!)
                    : null,
            child: driver.avatarUrl == null || driver.avatarUrl!.isEmpty
                ? const Icon(Icons.person_rounded, color: Color(0xFF1E3A5F))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  driver.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                _DriverVehicleBadge(
                  vehicleType:
                      isMotorcycle ? driverOwnMotorcycleType : driverBranchTruckType,
                  assignedVehicleCode: driver.assignedVehicleCode,
                ),
                if (!isMotorcycle) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _truckCodeCtrl,
                    decoration: InputDecoration(
                      labelText: 'លេខកូដឡានរបស់សាខា',
                      hintText: 'ឧទាហរណ៍ TRK-01',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE3EE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE3EE)),
                      ),
                      helperText:
                          'បញ្ចូលលេខកូដឡានដែលអ្នកបើកបរនេះនឹងប្រើ។',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: _saving ||
                              truckCode.isEmpty ||
                              truckCode == (widget.driver.assignedVehicleCode ?? '')
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              try {
                                await widget.onUpdateVehicleType(
                                  driverBranchTruckType,
                                  truckCode,
                                );
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: Text(_saving ? 'Saving...' : 'Save Truck Code'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: driver.isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              driver.isActive ? 'សកម្ម' : 'អសកម្ម',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: driver.isActive
                    ? const Color(0xFF166534)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverVehicleBadge extends StatelessWidget {
  final String? vehicleType;
  final String? assignedVehicleCode;

  const _DriverVehicleBadge({
    required this.vehicleType,
    this.assignedVehicleCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vehicleTypeIcon(vehicleType),
            size: 15,
            color: const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 6),
          Text(
            assignedVehicleCode?.isNotEmpty == true
                ? 'ឡានសាខា • ${assignedVehicleCode!}'
                : vehicleTypeLabel(vehicleType),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}
