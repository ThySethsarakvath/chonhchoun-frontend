import 'package:flutter/material.dart';

import '../models/driver_package.dart';
import 'driver_colors.dart';
import 'driver_shell_widgets.dart';

class DriverDeliveryCard extends StatelessWidget {
  const DriverDeliveryCard({super.key, required this.package});

  final DriverPackage package;

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: DriverColors.blue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: DriverColors.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package.trackingNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DriverColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: package.statusLabel, active: package.isActive),
            ],
          ),
          if (package.pickupAddress != null ||
              package.dropoffAddress != null) ...[
            const SizedBox(height: 14),
            _AddressLine(
              icon: Icons.radio_button_checked_rounded,
              color: DriverColors.danger,
              label: package.pickupAddress ?? 'Pickup',
            ),
            const SizedBox(height: 6),
            _AddressLine(
              icon: Icons.location_on_rounded,
              color: DriverColors.success,
              label: package.dropoffAddress ?? 'Drop-off',
            ),
          ],
          if (package.recipient.isNotEmpty || package.paymentMethod != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 16, color: DriverColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    package.recipient,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DriverColors.muted),
                  ),
                ),
                if (package.paymentMethod != null)
                  Text(
                    package.paymentMethod!,
                    style: const TextStyle(
                      color: DriverColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: DriverColors.text, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? DriverColors.success : DriverColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
