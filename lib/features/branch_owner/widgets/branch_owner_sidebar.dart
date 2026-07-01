import 'package:flutter/material.dart';

class BranchOwnerSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const BranchOwnerSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      minExtendedWidth: 230,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            const SizedBox(height: 12),
            const Text(
              'Branch Owner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.storefront_outlined),
          label: Text('Branch Info'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.groups_outlined),
          label: Text('Driver Management'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: Text('Packages'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          label: Text('Branch Logistics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: Text('Branch Wallet'),
        ),
      ],
    );
  }
}
