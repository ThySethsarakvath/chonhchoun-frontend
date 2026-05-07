import 'package:flutter/material.dart';

import '../../../shared/data/demo_data.dart';
import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/app_button_widgets.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_map_widgets.dart';
import '../../../shared/widgets/app_request_widgets.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class DriverProfileTab extends StatelessWidget {
  const DriverProfileTab({
    super.key,
    required this.request,
    required this.onOpenMap,
  });

  final DriverRequest request;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Account and readiness',
          name: driverDisplayName,
          content: const AppStatusSummary(),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              children: [
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle',
                        style: TextStyle(
                          color: AppColors.text,
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
                              color: AppColors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Motorbike Courier',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fast urban delivery with compact parcels',
                                  style: TextStyle(color: AppColors.muted),
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
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned hotspot',
                        style: TextStyle(
                          color: AppColors.text,
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
                        child: AppPrimaryButton(
                          label: 'Open Live Map',
                          onPressed: onOpenMap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppSurfaceCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: request.accent.withValues(alpha: 0.12),
                        child: Text(
                          request.senderInitials,
                          style: TextStyle(
                            color: request.accent,
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
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next package: ${request.title}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const AppStatusChip(label: 'Online'),
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
