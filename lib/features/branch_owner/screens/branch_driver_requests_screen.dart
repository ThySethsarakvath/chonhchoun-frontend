import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../driver_registration/models/driver_application_model.dart';
import '../../driver_registration/models/vehicle_type.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchDriverRequestsScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<DriverApplication> applications;
  final Future<void> Function() onRefresh;
  final Future<void> Function(
    DriverApplication application,
    String? vehicleType, {
    String? assignedVehicleCode,
  }) onApprove;
  final Future<void> Function(DriverApplication application, String? reason)
      onReject;

  const BranchDriverRequestsScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.applications,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading driver requests...',
      );
    }

    if (error != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load driver requests',
        description: error!,
        actionLabel: 'Try again',
        onAction: onRefresh,
      );
    }

    if (applications.isEmpty) {
      return BranchOwnerMessageCard(
        title: 'No driver requests yet',
        description:
            'New driver applications sent to your branch will appear here.',
        actionLabel: 'Refresh',
        onAction: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'Driver Requests',
          description:
              'Review documents, approve city express riders with their own motorcycles, or reject requests. Branch vehicles can still be assigned later for branch-driver roles.',
        ),
        const SizedBox(height: 14),
        ...applications.map(
          (application) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DriverApplicationCard(
              application: application,
              onApprove: (vehicleType, {assignedVehicleCode}) => onApprove(
                application,
                vehicleType,
                assignedVehicleCode: assignedVehicleCode,
              ),
              onReject: (reason) => onReject(application, reason),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverApplicationCard extends StatefulWidget {
  final DriverApplication application;
  final Future<void> Function(
    String? vehicleType, {
    String? assignedVehicleCode,
  }) onApprove;
  final Future<void> Function(String? reason) onReject;

  const _DriverApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_DriverApplicationCard> createState() => _DriverApplicationCardState();
}

class _DriverApplicationCardState extends State<_DriverApplicationCard> {
  Future<void> _promptReject(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Driver Request'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onReject(
        controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final isPending = application.status == 'pending';
    final isOwnVehicleApplication =
        application.vehicleType != null &&
        application.vehicleType != driverBranchTruckChoice;
    final effectiveVehicleType =
        isOwnVehicleApplication
            ? application.vehicleType
            : driverBranchTruckChoice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              _StatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${application.email} | ${application.phone}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Text(
            'Branch: ${application.branch?.name ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          _VehicleTypeBadge(
            vehicleType: effectiveVehicleType,
            assignedVehicleCode: application.assignedVehicleCode,
          ),
          if (application.plateNumber?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _InfoChip(label: 'Plate: ${application.plateNumber!}'),
          ],
          if (isPending &&
              application.vehicleType == driverOwnMotorcycleType) ...[
            const SizedBox(height: 12),
            const Text(
              'Approving this request keeps the rider on their own motorbike for city express delivery.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF047857),
                height: 1.4,
              ),
            ),
          ],
          if (isPending && !isOwnVehicleApplication) ...[
            const SizedBox(height: 12),
            const Text(
              'Approve first, then assign an existing branch vehicle later from Driver Management.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LinkChip(label: 'Photo', url: application.avatarUrl),
              _LinkChip(label: 'CV', url: application.cvUrl),
              _LinkChip(label: 'National ID', url: application.nationalIdUrl),
              _LinkChip(
                label: 'Driving License',
                url: application.drivingLicenseUrl,
              ),
            ],
          ),
          if (application.rejectionReason != null &&
              application.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Reason: ${application.rejectionReason}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => widget.onApprove(
                    isOwnVehicleApplication ? null : driverTruckType,
                    assignedVehicleCode: null,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    application.vehicleType == driverOwnMotorcycleType
                        ? 'Approve City Express'
                        : 'Approve',
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _promptReject(context),
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isApproved = normalized == 'approved';
    final isRejected = normalized == 'rejected';
    final backgroundColor = isApproved
        ? const Color(0xFFDCFCE7)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final foregroundColor = isApproved
        ? const Color(0xFF166534)
        : isRejected
            ? const Color(0xFFB91C1C)
            : const Color(0xFF92400E);
    final statusLabel = isApproved
        ? 'Approved'
        : isRejected
            ? 'Rejected'
            : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _VehicleTypeBadge extends StatelessWidget {
  final String? vehicleType;
  final String? assignedVehicleCode;

  const _VehicleTypeBadge({
    required this.vehicleType,
    this.assignedVehicleCode,
  });

  @override
  Widget build(BuildContext context) {
    final label = assignedVehicleCode?.isNotEmpty == true
        ? 'Branch Vehicle - ${assignedVehicleCode!}'
        : vehicleType == driverBranchTruckChoice
            ? 'Branch Vehicle'
            : reviewVehicleTypeLabel(vehicleType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vehicleTypeIcon(vehicleType),
            size: 16,
            color: const Color(0xFF075985),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF075985),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final String label;
  final String? url;

  const _LinkChip({
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: url == null || url!.isEmpty
            ? null
            : () => launchUrl(Uri.parse(url!)),
        borderRadius: BorderRadius.circular(999),
        child: Text(
          url == null || url!.isEmpty ? '$label missing' : 'Open $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

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
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
