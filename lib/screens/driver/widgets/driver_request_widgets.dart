import 'package:flutter/material.dart';

import '../models/driver_request.dart';
import 'driver_button_widgets.dart';
import 'driver_colors.dart';
import 'driver_shell_widgets.dart';

class DriverBalanceCard extends StatelessWidget {
  const DriverBalanceCard({
    super.key,
    required this.amount,
  });

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available balance',
            style: TextStyle(
              color: DriverColors.text,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  color: DriverColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                amount,
                style: const TextStyle(
                  color: DriverColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: DriverColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverStatusSummary extends StatelessWidget {
  const DriverStatusSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver status',
                  style: TextStyle(color: DriverColors.text, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'Ready for pickups',
                  style: TextStyle(
                    color: DriverColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          DriverStatusChip(label: 'Online'),
        ],
      ),
    );
  }
}

class DriverHomeRequestPreview extends StatelessWidget {
  const DriverHomeRequestPreview({
    super.key,
    required this.request,
    required this.onTap,
    this.showButtons = true,
  });

  final DriverRequest request;
  final VoidCallback onTap;
  final bool showButtons;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: request.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      request.fee,
                      style: TextStyle(
                        color: request.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recipient: ${request.recipient}',
                style: const TextStyle(color: DriverColors.muted),
              ),
              const SizedBox(height: 14),
              DriverMiniRouteLine(
                pickup: request.pickup,
                dropOff: request.dropOff,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  DriverDetailChip(icon: Icons.timer_outlined, text: request.eta),
                  const SizedBox(width: 10),
                  DriverDetailChip(
                    icon: Icons.credit_card_outlined,
                    text: request.payment,
                  ),
                ],
              ),
              if (showButtons) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: DriverSoftButton(
                        label: 'Reject',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DriverPrimaryButton(
                        label: 'Accept',
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DriverRequestCard extends StatelessWidget {
  const DriverRequestCard({
    super.key,
    required this.request,
    required this.onOpenDetail,
  });

  final DriverRequest request;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    color: DriverColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                request.fee,
                style: TextStyle(
                  color: request.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Recipient: ${request.recipient}',
            style: const TextStyle(color: DriverColors.muted),
          ),
          const SizedBox(height: 16),
          DriverMiniRouteLine(
            pickup: request.pickup,
            dropOff: request.dropOff,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DriverSoftButton(
                  label: 'Reject',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DriverPrimaryButton(
                  label: 'Accept',
                  onPressed: onOpenDetail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverMiniRouteLine extends StatelessWidget {
  const DriverMiniRouteLine({
    super.key,
    required this.pickup,
    required this.dropOff,
  });

  final String pickup;
  final String dropOff;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          children: [
            Icon(Icons.location_on_rounded, size: 18, color: DriverColors.danger),
            SizedBox(height: 2),
            Icon(Icons.more_vert_rounded, size: 16, color: DriverColors.line),
            SizedBox(height: 2),
            Icon(Icons.circle_rounded, size: 14, color: DriverColors.success),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup  $pickup',
                style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                dropOff,
                style: const TextStyle(
                  color: DriverColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DriverDetailChip extends StatelessWidget {
  const DriverDetailChip({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DriverColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: DriverColors.blue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DriverInfoBlock extends StatelessWidget {
  const DriverInfoBlock({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DriverColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? DriverColors.blue : DriverColors.text,
            fontSize: emphasize ? 24 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class DriverRoutePoint extends StatelessWidget {
  const DriverRoutePoint({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 18 : 20, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: compact
              ? const SizedBox(height: 10)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: DriverColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class DriverPickupThumbnail extends StatelessWidget {
  const DriverPickupThumbnail({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
