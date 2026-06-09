import 'package:flutter/material.dart';

import '../data/driver_demo_data.dart';
import '../models/driver_request.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverDeliveriesTab extends StatelessWidget {
  const DriverDeliveriesTab({
    super.key,
    required this.request,
    required this.onViewAll,
    required this.onOpenDetail,
  });

  final DriverRequest request;
  final VoidCallback onViewAll;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Weekly Overview',
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
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: DriverColors.blue,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                driverOverviewRange,
                                style: TextStyle(
                                  color: DriverColors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: DriverColors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const DriverStatLine(
                        label: 'Time',
                        value: driverTotalTime,
                      ),
                      const SizedBox(height: 18),
                      const DriverStatLine(
                        label: 'Deliveries',
                        value: driverTotalDeliveries,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: DriverPrimaryButton(
                          label: 'See Details',
                          onPressed: onOpenDetail,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DriverSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current request',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DriverHomeRequestPreview(
                        request: request,
                        onTap: onOpenDetail,
                        showButtons: false,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onViewAll,
                          child: const Text(
                            'Open request queue',
                            style: TextStyle(
                              color: DriverColors.blue,
                              fontWeight: FontWeight.w700,
                            ),
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
