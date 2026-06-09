import 'package:flutter/material.dart';

import '../data/driver_demo_data.dart';
import '../models/driver_request.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverHomeTab extends StatelessWidget {
  const DriverHomeTab({
    super.key,
    required this.requests,
    required this.onViewAll,
    required this.onOpenDetail,
  });

  final List<DriverRequest> requests;
  final VoidCallback onViewAll;
  final ValueChanged<DriverRequest> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Welcome Back',
          name: driverDisplayName,
          content: const DriverBalanceCard(amount: driverAvailableBalance),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              children: [
                DriverSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Would you like to specify direction for deliveries?',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: onViewAll,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          height: 54,
                          decoration: BoxDecoration(
                            color: DriverColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 16),
                              Icon(
                                Icons.radio_button_checked_rounded,
                                color: DriverColors.blue,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Where to?',
                                style: TextStyle(
                                  color: DriverColors.muted,
                                  fontSize: 15,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: DriverColors.muted,
                              ),
                              SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Available Requests',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: DriverColors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DriverHomeRequestPreview(
                  request: requests.first,
                  onTap: () => onOpenDetail(requests.first),
                ),
                const SizedBox(height: 14),
                DriverSurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: DriverColors.blue.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: DriverColors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Complete onboarding to start taking requests',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
