import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../../admin_management/screens/admin_branch_screen.dart';
import '../../admin_management/screens/admin_agent_screen.dart'; // New Import
import '../../agencies_management/services/branch_service.dart';
import '../../agencies_management/models/branch_model.dart';

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

  // Fetch branches once at the shell level to share with both screens
  Future<void> _loadInitialData() async {
    try {
      final data = await _branchService.getAllBranches();
      setState(() {
        _branches = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Desktop-specific views integrated into the shell
    final List<Widget> _adminViews = [
      const Center(child: Text("ផ្ទាំងគ្រប់គ្រងទូទៅ (System Overview)")), 
      const AdminBranchScreen(), 
      _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : AdminAgentScreen(branches: _branches), // Tracking Agent View
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

          // Flexible content area that switches based on sidebar selection
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC), 
              child: _adminViews[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}