import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      minExtendedWidth: 220,
      backgroundColor: const Color(0xFF1E3A5F),
      unselectedIconTheme: const IconThemeData(color: Colors.white60),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white60),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Image.asset('assets/images/logo.png', height: 40),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_tree_outlined),
          label: Text('Branches'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_pin_circle_outlined),
          label: Text('Agents'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          label: Text('Users'),
        ),
      ],
    );
  }
}
