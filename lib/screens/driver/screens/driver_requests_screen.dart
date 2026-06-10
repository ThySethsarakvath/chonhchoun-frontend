import 'package:flutter/material.dart';

import '../data/driver_demo_data.dart';
import '../models/driver_request.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverRequestsScreen extends StatelessWidget {
  const DriverRequestsScreen({
    super.key,
    required this.requests,
    required this.onOpenDetail,
  });

  final List<DriverRequest> requests;
  final ValueChanged<DriverRequest> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DriverHeroSection(
            subtitle: 'Welcome Back',
            name: driverDisplayName,
            leading: DriverBackChip(onTap: () => Navigator.of(context).pop()),
            content: const DriverBalanceCard(amount: driverAvailableBalance),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
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
                        Container(
                          height: 52,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Available Requests',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: DriverColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DriverRequestCard(
                        request: request,
                        onOpenDetail: () => onOpenDetail(request),
                      ),
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
