import 'package:flutter/material.dart';

import '../../../driver/widgets/driver_shell_widgets.dart';
import '../../widgets/customer_colors.dart';

class CustomerProfileActionsCard extends StatelessWidget {
  const CustomerProfileActionsCard({
    super.key,
    required this.onLogoutTap,
  });

  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: DriverSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: CustomerColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Placeholder for the next auth step.',
              isDanger: true,
              onTap: onLogoutTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? CustomerColors.danger : CustomerColors.blueDark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: CustomerColors.muted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: CustomerColors.muted,
      ),
      onTap: onTap,
    );
  }
}
