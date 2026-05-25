import 'package:flutter/material.dart';

import 'branch_owner_content_widgets.dart';

class BranchOwnerOverviewSection extends StatelessWidget {
  final String salesTodayLabel;
  final String driverAgentCountLabel;
  final String pendingRequestsLabel;

  const BranchOwnerOverviewSection({
    super.key,
    required this.salesTodayLabel,
    required this.driverAgentCountLabel,
    required this.pendingRequestsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionHero(
          title: 'Welcome to your branch workspace',
          description:
              'Use this portal to monitor branch operations, review performance, manage drivers, and approve branch-level driver requests.',
          icon: Icons.storefront_rounded,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            BranchOwnerStatCard(
              label: 'Sales Today',
              value: salesTodayLabel,
              icon: Icons.payments_rounded,
              color: const Color(0xFF15803D),
            ),
            BranchOwnerStatCard(
              label: 'Driver Agents',
              value: driverAgentCountLabel,
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF1D4ED8),
            ),
            BranchOwnerStatCard(
              label: 'Pending Requests',
              value: pendingRequestsLabel,
              icon: Icons.assignment_late_rounded,
              color: const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const BranchOwnerSectionCard(
          title: 'What this portal is for',
          description:
              'This workspace is focused on branch-owner operations. Branch identity and profile control stay under admin, while branch owners focus on branch performance, driver visibility, and request approvals.',
        ),
      ],
    );
  }
}

class BranchOwnerBranchInformationSection extends StatelessWidget {
  final Widget branchInfoContent;

  const BranchOwnerBranchInformationSection({
    super.key,
    required this.branchInfoContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'Branch Profile',
          description: 'Branch information is controlled by admin.',
        ),
        const SizedBox(height: 14),
        branchInfoContent,
      ],
    );
  }
}

class BranchOwnerSalesSection extends StatelessWidget {
  const BranchOwnerSalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'Branch Sales Monitoring',
          description:
              'This section should help branch owners understand how the branch is performing through sales, orders, and day-to-day branch activity.',
        ),
        const SizedBox(height: 14),
        BranchOwnerFeatureListCard(
          title: 'Planned tools',
          items: const [
            'Daily, weekly, and monthly sales totals',
            'Order count and completed deliveries',
            'Revenue summary and branch performance snapshot',
            'Top service or activity trends',
          ],
        ),
      ],
    );
  }
}

class BranchOwnerDriverAgentsSection extends StatelessWidget {
  const BranchOwnerDriverAgentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'Driver Agent List',
          description:
              'This section should show the driver agents connected to the branch so branch owners can monitor who is active and who belongs to the branch.',
        ),
        const SizedBox(height: 14),
        BranchOwnerFeatureListCard(
          title: 'Planned tools',
          items: const [
            'List all branch driver agents',
            'View driver contact and status',
            'Check active and inactive driver availability',
            'Review branch-driver operational visibility',
          ],
        ),
      ],
    );
  }
}

class BranchOwnerDriverRequestsSection extends StatelessWidget {
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenApproval;

  const BranchOwnerDriverRequestsSection({
    super.key,
    required this.onOpenRequests,
    required this.onOpenApproval,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BranchOwnerSectionCard(
          title: 'Driver Application Review',
          description:
              'Branch owners can review driver-agent requests submitted from the branch side and decide whether each request should be approved or rejected.',
        ),
        const SizedBox(height: 14),
        BranchOwnerFeatureListCard(
          title: 'Request information to review',
          items: const [
            'Driver full name and contact details',
            'Driver license upload',
            'CV or resume attachment',
            'National ID or identity document',
          ],
          onAction: onOpenRequests,
        ),
        const SizedBox(height: 14),
        BranchOwnerFeatureListCard(
          title: 'Approval actions',
          items: const [
            'Open the request details clearly',
            'Check all uploaded driver documents',
            'Approve a request for driver-agent onboarding',
            'Reject a request with a reason message',
          ],
          onAction: onOpenApproval,
        ),
      ],
    );
  }
}
