import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/services/auth_service.dart';
import '../../branch_owner/widgets/branch_owner_content_widgets.dart';
import '../../driver_registration/models/driver_application_model.dart';
import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../services/admin_vehicle_service.dart';

class AdminDriverRequestsScreen extends StatefulWidget {
  const AdminDriverRequestsScreen({super.key});

  @override
  State<AdminDriverRequestsScreen> createState() =>
      _AdminDriverRequestsScreenState();
}

class _AdminDriverRequestsScreenState extends State<AdminDriverRequestsScreen> {
  final _vehicleService = AdminVehicleService();

  bool _loading = true;
  String? _error;
  List<DriverApplication> _applications = const [];
  List<ManagedVehicle> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<DriverApplication> get _branchVehicleApplications => _applications
      .where((application) {
        final type = application.vehicleType;
        return type == null ||
            type == driverBranchTruckChoice ||
            type == driverTruckType ||
            type == driverLargeTruckType;
      })
      .toList();

  List<DriverApplication> get _pendingApplications => _branchVehicleApplications
      .where((application) => application.status == 'pending')
      .toList();

  List<DriverApplication> get _reviewedApplications => _branchVehicleApplications
      .where((application) => application.status != 'pending')
      .toList();

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _vehicleService.getApplications(),
        _vehicleService.getVehicles(),
      ]);

      if (!mounted) return;
      setState(() {
        _applications = results[0] as List<DriverApplication>;
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

  Future<void> _approveApplication(DriverApplication application) async {
    String vehicleType = application.vehicleType == driverLargeTruckType
        ? driverLargeTruckType
        : driverTruckType;
    String? assignedVehicleCode;
    final branchVehicles = _vehicles
        .where(
          (vehicle) =>
              vehicle.branchId == application.branch?.id &&
              vehicle.isCompanyVehicle &&
              vehicle.isActive &&
              vehicle.status == 'AVAILABLE',
        )
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Approve ${application.name}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: vehicleType,
                    decoration: const InputDecoration(labelText: 'Driver type'),
                    items: branchVehicleTypeOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => vehicleType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: assignedVehicleCode,
                    decoration: const InputDecoration(
                      labelText: 'Assign company vehicle now',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Approve without vehicle assignment'),
                      ),
                      ...branchVehicles.map(
                        (vehicle) => DropdownMenuItem<String>(
                          value: vehicle.code,
                          child: Text(
                            '${vehicle.code} - ${vehicle.branchName ?? 'No branch'}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => assignedVehicleCode = value),
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
                  await _vehicleService.approveApplication(
                    application.id,
                    vehicleType: vehicleType,
                    assignedVehicleCode: assignedVehicleCode,
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
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectApplication(DriverApplication application) async {
    final reasonCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reject ${application.name}'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Optional rejection reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _vehicleService.rejectApplication(
                  application.id,
                  reason: reasonCtrl.text.trim(),
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading driver requests...',
      );
    }

    if (_error != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load driver requests',
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
            title: 'Driver Requests',
            description:
                'Review branch driver applications here as a separate admin feature. Pending requests stay here until you approve or reject them.',
            icon: Icons.assignment_rounded,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              BranchOwnerStatCard(
                label: 'Pending Requests',
                value: '${_pendingApplications.length}',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFB45309),
              ),
              BranchOwnerStatCard(
                label: 'Reviewed Requests',
                value: '${_reviewedApplications.length}',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF1D4ED8),
              ),
              BranchOwnerStatCard(
                label: 'Available Vehicles',
                value:
                    '${_vehicles.where((vehicle) => vehicle.isActive && vehicle.status == 'AVAILABLE').length}',
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF15803D),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const BranchOwnerSectionCard(
            title: 'Pending Driver Applications',
            description:
                'This is the full request area for driver applications. Review the branch, requested vehicle type, contact details, uploaded documents, and then approve or reject separately from vehicle management.',
          ),
          const SizedBox(height: 14),
          if (_pendingApplications.isEmpty)
            const BranchOwnerMessageCard(
              title: 'No pending driver requests',
              description:
                  'New branch truck and large-truck applications will appear here.',
            )
          else
            ..._pendingApplications.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AdminApplicationCard(
                  application: application,
                  onApprove: () => _approveApplication(application),
                  onReject: () => _rejectApplication(application),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const BranchOwnerSectionCard(
            title: 'Reviewed Applications',
            description:
                'Previously approved or rejected applications stay here for follow-up and history.',
          ),
          const SizedBox(height: 14),
          if (_reviewedApplications.isEmpty)
            const BranchOwnerMessageCard(
              title: 'No reviewed applications yet',
              description: 'Approved and rejected driver requests will appear here.',
            )
          else
            ..._reviewedApplications.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AdminApplicationCard(
                  application: application,
                  onApprove: null,
                  onReject: null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminApplicationCard extends StatelessWidget {
  final DriverApplication application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final requestedVehicle = reviewVehicleTypeLabel(application.vehicleType);
    final isPending = application.status == 'pending';

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
                      application.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${application.email} | ${application.phone}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              _ApplicationStatusPill(status: application.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RequestChip(label: 'Branch: ${application.branch?.name ?? '-'}'),
              _RequestChip(label: 'Requested vehicle: $requestedVehicle'),
              if (application.assignedVehicleCode?.isNotEmpty == true)
                _RequestChip(
                  label: 'Assigned vehicle: ${application.assignedVehicleCode!}',
                ),
              if (application.plateNumber?.isNotEmpty == true)
                _RequestChip(label: 'Plate: ${application.plateNumber!}'),
              if (application.maxWeightKg != null)
                _RequestChip(label: 'Weight: ${application.maxWeightKg} kg'),
              if (application.maxPackageCount != null)
                _RequestChip(label: 'Packages: ${application.maxPackageCount}'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Uploaded documents',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RequestLinkChip(label: 'Photo', url: application.avatarUrl),
              _RequestLinkChip(label: 'CV', url: application.cvUrl),
              _RequestLinkChip(
                label: 'National ID',
                url: application.nationalIdUrl,
              ),
              _RequestLinkChip(
                label: 'Driving License',
                url: application.drivingLicenseUrl,
              ),
            ],
          ),
          if (application.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Text(
              'Rejection reason: ${application.rejectionReason!}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB45309),
              ),
            ),
          ],
          if (isPending && onApprove != null && onReject != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  final String status;

  const _ApplicationStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'approved':
        return const _StatusPill(
          label: 'Approved',
          foreground: Color(0xFF166534),
          background: Color(0xFFDCFCE7),
        );
      case 'rejected':
        return const _StatusPill(
          label: 'Rejected',
          foreground: Color(0xFF991B1B),
          background: Color(0xFFFEE2E2),
        );
      default:
        return const _StatusPill(
          label: 'Pending',
          foreground: Color(0xFF9A3412),
          background: Color(0xFFFFEDD5),
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

class _RequestChip extends StatelessWidget {
  final String label;

  const _RequestChip({required this.label});

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

class _RequestLinkChip extends StatelessWidget {
  final String label;
  final String? url;

  const _RequestLinkChip({
    required this.label,
    required this.url,
  });

  Future<void> _openUrl() async {
    if (url == null || url!.isEmpty) return;
    final uri = Uri.tryParse(url!);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = url != null && url!.isNotEmpty;
    return OutlinedButton.icon(
      onPressed: enabled ? _openUrl : null,
      icon: const Icon(Icons.attach_file_rounded),
      label: Text(label),
    );
  }
}
