import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../driver_registration/models/driver_application_model.dart';
import '../widgets/branch_owner_content_widgets.dart';

class BranchDriverRequestsScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<DriverApplication> applications;
  final Future<void> Function() onRefresh;
  final Future<void> Function(DriverApplication application) onApprove;
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
        message: 'កំពុងផ្ទុកពាក្យស្នើសុំអ្នកបើកបរ...',
      );
    }

    if (error != null) {
      return BranchOwnerMessageCard(
        title: 'មិនអាចផ្ទុកសំណើអ្នកបើកបរបានទេ',
        description: error!,
        actionLabel: 'ព្យាយាមម្តងទៀត',
        onAction: onRefresh,
      );
    }

    if (applications.isEmpty) {
      return BranchOwnerMessageCard(
        title: 'មិនទាន់មានសំណើអ្នកបើកបរនៅឡើយទេ',
        description:
            'ពាក្យស្នើសុំអ្នកបើកបរថ្មីៗដែលផ្ញើមកសាខារបស់អ្នកនឹងបង្ហាញនៅទីនេះ។',
        actionLabel: 'ផ្ទុកឡើងវិញ',
        onAction: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'ពិនិត្យពាក្យស្នើសុំអ្នកបើកបរ',
          description:
              'ពិនិត្យឯកសារដែលអ្នកបើកបរបានបង្ហោះ ហើយអនុម័ត ឬបដិសេធពាក្យស្នើសុំនីមួយៗ។',
        ),
        const SizedBox(height: 14),
        ...applications.map(
          (application) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DriverApplicationCard(
              application: application,
              onApprove: () => onApprove(application),
              onReject: (reason) => onReject(application, reason),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverApplicationCard extends StatelessWidget {
  final DriverApplication application;
  final Future<void> Function() onApprove;
  final Future<void> Function(String? reason) onReject;

  const _DriverApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  Future<void> _promptReject(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('បដិសេធពាក្យស្នើសុំ'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'មូលហេតុបដិសេធ (បើមាន)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('បដិសេធ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onReject(controller.text.trim().isEmpty ? null : controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = application.status == 'pending';
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
            '${application.email} • ${application.phone}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Text(
            'សាខា: ${application.branch?.name ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LinkChip(label: 'រូបភាព', url: application.avatarUrl),
              _LinkChip(label: 'CV', url: application.cvUrl),
              _LinkChip(label: 'អត្តសញ្ញាណប័ណ្ណ', url: application.nationalIdUrl),
              _LinkChip(label: 'ប័ណ្ណបើកបរ', url: application.drivingLicenseUrl),
            ],
          ),
          if (application.rejectionReason != null &&
              application.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'មូលហេតុ: ${application.rejectionReason}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('អនុម័ត'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _promptReject(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('បដិសេធ'),
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
        ? 'អនុម័ត'
        : isRejected
            ? 'បដិសេធ'
            : 'កំពុងរង់ចាំ';

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
          url == null || url!.isEmpty ? '$label មិនមាន' : 'បើក $label',
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
