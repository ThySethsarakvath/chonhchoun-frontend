import 'package:flutter/material.dart';

import '../widgets/branch_owner_sections.dart';

class BranchOwnerOverviewScreen extends StatelessWidget {
  final String salesTodayLabel;
  final String driverAgentCountLabel;
  final String pendingRequestsLabel;

  const BranchOwnerOverviewScreen({
    super.key,
    required this.salesTodayLabel,
    required this.driverAgentCountLabel,
    required this.pendingRequestsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BranchOwnerOverviewSection(
      salesTodayLabel: salesTodayLabel,
      driverAgentCountLabel: driverAgentCountLabel,
      pendingRequestsLabel: pendingRequestsLabel,
    );
  }
}
