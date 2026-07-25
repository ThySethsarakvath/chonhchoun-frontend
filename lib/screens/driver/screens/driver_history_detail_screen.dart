import 'package:flutter/material.dart';

import '../../../shared/models/driver_request.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';

class DriverHistoryDetailScreen extends StatelessWidget {
  const DriverHistoryDetailScreen({required this.request, super.key});

  final DriverRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
      appBar: AppBar(
        backgroundColor: DriverColors.blueDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Delivery details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  DriverSurfaceCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: DriverColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: DriverColors.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery completed',
                                style: TextStyle(
                                  color: DriverColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                request.id == null
                                    ? 'Completed express delivery'
                                    : 'Reference ${request.id}',
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
                        Text(
                          request.fee,
                          style: const TextStyle(
                            color: DriverColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DriverSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completed route',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _HistoryRoutePoint(
                          icon: Icons.inventory_2_rounded,
                          color: DriverColors.blue,
                          label: 'Pickup',
                          value: request.pickup,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 19),
                          child: SizedBox(
                            height: 24,
                            child: VerticalDivider(
                              width: 2,
                              thickness: 2,
                              color: DriverColors.line,
                            ),
                          ),
                        ),
                        _HistoryRoutePoint(
                          icon: Icons.flag_rounded,
                          color: DriverColors.success,
                          label: 'Drop-off',
                          value: request.dropOff,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DriverSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery summary',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SummaryRow(
                          label: 'Package',
                          value: request.itemSummary,
                        ),
                        _SummaryRow(
                          label: 'Recipient',
                          value: request.recipient,
                        ),
                        _SummaryRow(label: 'Payment', value: request.payment),
                        _SummaryRow(
                          label: 'Vehicle',
                          value: request.vehicleType == 'RICKSHAW'
                              ? 'Rickshaw'
                              : 'Motorbike',
                        ),
                        _SummaryRow(
                          label: 'Status',
                          value: 'Delivered',
                          valueColor: DriverColors.success,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRoutePoint extends StatelessWidget {
  const _HistoryRoutePoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: const TextStyle(
                  color: DriverColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = DriverColors.text,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DriverColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
