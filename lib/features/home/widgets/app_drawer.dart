import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';

class _DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  final String city;
  final String? avatarUrl; // asset path
  final UserProfile? userProfile;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onClose;
  final VoidCallback onProfileTap;

  const AppDrawer({
    super.key,
    required this.city,
    required this.avatarUrl,
    required this.userProfile,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onClose,
    required this.onProfileTap,
  });

  static List<_DrawerItem> _buildItems(ValueChanged<int> onItemSelected) => [
    _DrawerItem(
      icon: Icons.my_location_outlined,
      label: 'តាមដាន',
      onTap: () => onItemSelected(0),
    ),
    _DrawerItem(
      icon: Icons.notifications_outlined,
      label: 'ការជូនដំណឹង',
      onTap: () => onItemSelected(1),
    ),
    _DrawerItem(
      icon: Icons.bar_chart_rounded,
      label: 'វិភាគ',
      onTap: () => onItemSelected(2),
    ),
    _DrawerItem(
      icon: Icons.local_shipping_outlined,
      label: 'ការដឹកជញ្ជូន',
      onTap: () => onItemSelected(3),
    ),
    _DrawerItem(
      icon: Icons.person_outline_rounded,
      label: 'គណនី',
      onTap: () => onItemSelected(4),
    ),
    _DrawerItem(
      icon: Icons.settings_outlined,
      label: 'ការកំណត់',
      onTap: () => onItemSelected(5),
    ),
    _DrawerItem(
      icon: Icons.help_outline_rounded,
      label: 'ជំនួយការ',
      onTap: () => onItemSelected(6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.78;
    final items = _buildItems(onItemSelected);

    return SizedBox(
      width: drawerWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E4D73), Color(0xFF2C6B9E), Color(0xFF2060A0)],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Logo box
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ជញ្ជូន',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      // Close button
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final selected = i == selectedIndex;
                      return _DrawerTile(
                        item: item,
                        selected: selected,
                        onTap: () {
                          item.onTap();
                          onClose();
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: GestureDetector(
                    onTap: onProfileTap,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 1.5),
                            color: const Color(0xFF4A8DDB),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl!.isNotEmpty
                                ? Image.network(
                                    avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/avatar.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile?.name ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                userProfile?.email ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.logout_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: selected ? Colors.white : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (selected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
