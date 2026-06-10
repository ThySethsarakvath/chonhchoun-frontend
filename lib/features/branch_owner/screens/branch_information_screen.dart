import 'package:flutter/material.dart';

import '../widgets/branch_owner_sections.dart';

class BranchInformationScreen extends StatelessWidget {
  final Widget branchInfoContent;

  const BranchInformationScreen({
    super.key,
    required this.branchInfoContent,
  });

  @override
  Widget build(BuildContext context) {
    return BranchOwnerBranchInformationSection(
      branchInfoContent: branchInfoContent,
    );
  }
}
