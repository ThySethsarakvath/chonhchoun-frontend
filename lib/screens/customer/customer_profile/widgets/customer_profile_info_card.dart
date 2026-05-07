import 'package:flutter/material.dart';

import '../../../driver/widgets/driver_shell_widgets.dart';
import '../../widgets/customer_colors.dart';

class CustomerProfileInfoCard extends StatelessWidget {
  const CustomerProfileInfoCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DriverSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Details',
              style: TextStyle(
                color: CustomerColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Name',
              value: name,
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Role',
              value: role,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: CustomerColors.softBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: CustomerColors.blueDark, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CustomerColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: CustomerColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
