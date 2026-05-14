import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
// Import your future branch and agency pages here

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  // List of pages to display in the main content area
  final List<Widget> _pages = [
    const Center(child: Text("ផ្ទាំងគ្រប់គ្រងទូទៅ")), // Dashboard Placeholder
    const Center(child: Text("គ្រប់គ្រងសាខា")),    // Branch Page Placeholder
    const Center(child: Text("គ្រប់គ្រងភ្នាក់ងារ")),  // Agency Page Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA), // Light grey background for professional feel
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }
}