import 'package:flutter/material.dart';

import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_button_widgets.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_map_widgets.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';

class DriverProfileTab extends StatelessWidget {
  const DriverProfileTab({
    super.key,
    required this.request,
    required this.onOpenMap,
  });

  final DriverRequest? request;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Account and readiness',
          name: 'Driver',
          content: DriverBalanceCard(amount: provider.balance.toStringAsFixed(2)),
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
                        'Vehicle',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: DriverColors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: DriverColors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.vehicleType,
                                  style: const TextStyle(
                                    color: DriverColors.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready for deliveries',
                                  style: TextStyle(color: DriverColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        'Assigned hotspot',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: const SizedBox(
                          height: 220,
                          child: DriverLeafletMapCard(
                            interactive: false,
                            showAttribution: false,
                            overlay: DriverProfileMapOverlay(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: DriverPrimaryButton(
                          label: 'Open Live Map',
                          onPressed: onOpenMap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DriverSurfaceCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (request?.accent ?? DriverColors.blue).withValues(alpha: 0.12),
                        child: Text(
                          request?.senderInitials ?? '?',
                          style: TextStyle(
                            color: request?.accent ?? DriverColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Readiness',
                              style: TextStyle(
                                color: DriverColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isOnline ? 'Online and ready' : 'Currently Offline',
                              style: const TextStyle(color: DriverColors.muted),
                            ),
                          ],
                        ),
                      ),
                      DriverStatusChip(
                        label: provider.isOnline ? 'Online' : 'Offline',
                        color: provider.isOnline ? DriverColors.green : DriverColors.muted,
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
