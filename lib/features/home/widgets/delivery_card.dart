import 'package:flutter/material.dart';
import '../models/home_models.dart';
import 'tracking_progress_bar.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryItem item;
  final bool showTracking;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.item,
    this.showTracking = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C5F8A).withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Package icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF2C5F8A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.trackingNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2D3D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              item.status.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8BA4C8),
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8BA4C8),
                              ),
                            ),
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8BA4C8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFBCC8D8),
                    size: 22,
                  ),
                ],
              ),
              if (showTracking && item.checkpoints.isNotEmpty) ...[
                const SizedBox(height: 16),
                TrackingProgressBar(checkpoints: item.checkpoints),
                const SizedBox(height: 10),

                // From / To labels
                Row(
                  children: [
                    const Text(
                      'ពី',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A8DDB),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'ទៅកាន់',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A8DDB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Origin / Destination names
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.origin,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3A4E),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.destination,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3A4E),
                        ),
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