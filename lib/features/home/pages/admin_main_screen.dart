import 'package:flutter/material.dart';

import '../../admin_management/models/branch_model.dart';
import '../../admin_management/screens/admin_agent_screen.dart';
import '../../admin_management/screens/admin_branch_screen.dart';
import '../../admin_management/screens/admin_user_screen.dart';
import '../../admin_management/services/branch_service.dart';
import '../widgets/admin_sidebar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final _branchService = BranchService();
  List<Branch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final data = await _branchService.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminViews = <Widget>[
      const Center(
        child: Text(
          'System overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      const AdminBranchScreen(),
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdminAgentScreen(branches: _branches),
      const AdminUserScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: adminViews[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
