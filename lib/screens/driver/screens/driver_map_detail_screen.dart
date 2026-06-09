import 'package:flutter/material.dart';

import '../models/driver_request.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_map_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverMapDetailScreen extends StatelessWidget {
  const DriverMapDetailScreen({
    super.key,
    required this.request,
  });

  final DriverRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
      bottomNavigationBar: DriverDecisionBar(
        primaryLabel: 'Accept',
        secondaryLabel: 'Reject',
        onPrimaryPressed: () => Navigator.of(context).pop(),
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [DriverColors.blueDark, DriverColors.blue],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      DriverBackChip(onTap: () => Navigator.of(context).pop()),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Request Map Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  DriverLeafletMapCard(
                    interactive: true,
                    showAttribution: true,
                    overlay: const DriverLiveMapOverlay(),
                    pickupLatLng: request.pickupLatLng,
                    dropOffLatLng: request.dropOffLatLng,
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            request.title,
                            style: const TextStyle(
                              color: DriverColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: DriverColors.danger),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.pickup,
                                  style: const TextStyle(color: DriverColors.muted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.circle_rounded, size: 14, color: DriverColors.success),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.dropOff,
                                  style: const TextStyle(color: DriverColors.muted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
