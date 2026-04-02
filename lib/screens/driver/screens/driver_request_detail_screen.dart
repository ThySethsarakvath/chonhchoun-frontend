import 'package:flutter/material.dart';

import '../models/driver_request.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_map_widgets.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverRequestDetailScreen extends StatelessWidget {
  const DriverRequestDetailScreen({
    super.key,
    required this.request,
    required this.onOpenMap,
  });

  final DriverRequest request;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
      bottomNavigationBar: DriverDecisionBar(
        primaryLabel: 'Accept',
        secondaryLabel: 'Reject',
        onPrimaryPressed: onOpenMap,
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DriverColors.blueDark, DriverColors.blue],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DriverBackChip(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: 18),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: const SizedBox(
                          height: 152,
                          width: 230,
                          child: DriverLeafletMapCard(
                            interactive: false,
                            showAttribution: false,
                            overlay: DriverPreviewRouteOverlay(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -82),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: DriverSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: request.accent.withValues(alpha: 0.15),
                          child: Text(
                            request.senderInitials,
                            style: TextStyle(
                              color: request.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.recipient,
                                style: const TextStyle(
                                  color: DriverColors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${request.deliveries} Deliveries',
                                style: const TextStyle(color: DriverColors.muted),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: DriverColors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: DriverColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: DriverColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    DriverRoutePoint(
                      icon: Icons.location_on_rounded,
                      iconColor: DriverColors.danger,
                      label: 'Pickup Location',
                      value: request.pickup,
                    ),
                    const DriverRoutePoint(
                      icon: Icons.more_vert_rounded,
                      iconColor: DriverColors.line,
                      label: '',
                      value: '',
                      compact: true,
                    ),
                    DriverRoutePoint(
                      icon: Icons.circle_rounded,
                      iconColor: DriverColors.success,
                      label: 'Delivery Location',
                      value: request.dropOff,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'What you are sending',
                            value: request.itemSummary,
                          ),
                        ),
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'Recipient',
                            value: request.recipient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'Recipient contact number',
                            value: request.phone,
                          ),
                        ),
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'Payment',
                            value: request.payment,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'Pickup ETA',
                            value: request.eta,
                          ),
                        ),
                        Expanded(
                          child: DriverInfoBlock(
                            label: 'Fee',
                            value: request.fee,
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Pickup image(s)',
                      style: TextStyle(
                        color: DriverColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        DriverPickupThumbnail(
                          icon: Icons.cake_rounded,
                          color: Color(0xFFF9B36A),
                        ),
                        SizedBox(width: 12),
                        DriverPickupThumbnail(
                          icon: Icons.local_grocery_store_rounded,
                          color: Color(0xFFE57373),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
