import 'package:flutter/material.dart';

import '../../../shared/widgets/driver_colors.dart';
import '../driver_provider.dart';
import '../widgets/express_driver_route_map.dart';
import 'driver_verification_scanner_screen.dart';

class DriverActiveDeliveryMapScreen extends StatelessWidget {
  const DriverActiveDeliveryMapScreen({required this.provider, super.key});

  final DriverProvider provider;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final request = provider.currentDelivery;
        if (request == null) {
          return Scaffold(
            backgroundColor: DriverColors.surface,
            appBar: AppBar(
              backgroundColor: DriverColors.blueDark,
              foregroundColor: Colors.white,
              title: const Text('Active delivery'),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This delivery is complete. You can return to the driver dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DriverColors.muted),
                ),
              ),
            ),
          );
        }

        final canScan =
            request.status == 'ARRIVED_AT_PICKUP' ||
            request.status == 'ARRIVED_AT_DROPOFF';
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ExpressDriverRouteMap(request: request, borderRadius: 0),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: DriverColors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon(request.status),
                                color: DriverColors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusTitle(request.status),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: DriverColors.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _statusMessage(request.status),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: DriverColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canScan) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => _openScanner(context, request.status!),
                            icon: provider.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_scanner_rounded),
                            label: Text(
                              request.status == 'ARRIVED_AT_PICKUP'
                                  ? 'Scan sender pickup QR'
                                  : 'Scan recipient completion QR',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: DriverColors.blue,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Material(
                        color: Colors.white,
                        elevation: 9,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RouteLine(
                                icon: Icons.inventory_2_rounded,
                                color: DriverColors.blue,
                                label: 'Pickup',
                                value: request.pickup,
                              ),
                              const SizedBox(height: 10),
                              _RouteLine(
                                icon: Icons.location_on_rounded,
                                color: DriverColors.danger,
                                label: 'Drop-off',
                                value: request.dropOff,
                              ),
                              const Divider(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      request.itemSummary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DriverColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    request.fee,
                                    style: const TextStyle(
                                      color: DriverColors.blue,
                                      fontWeight: FontWeight.w800,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openScanner(BuildContext context, String status) async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DriverVerificationScannerScreen(
          title: status == 'ARRIVED_AT_PICKUP'
              ? 'Verify Sender Handoff'
              : 'Verify Recipient Delivery',
          onVerify: provider.verifyDeliveryQr,
        ),
      ),
    );
    if (!context.mounted) return;
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery QR verified successfully.'),
          backgroundColor: DriverColors.success,
        ),
      );
    } else if (provider.lastError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastError!)));
    }
  }

  static IconData _statusIcon(String? status) {
    switch (status) {
      case 'ARRIVED_AT_PICKUP':
      case 'ARRIVED_AT_DROPOFF':
        return Icons.flag_circle_rounded;
      case 'IN_TRANSIT':
        return Icons.route_rounded;
      default:
        return Icons.delivery_dining_rounded;
    }
  }

  static String _statusTitle(String? status) {
    switch (status) {
      case 'ARRIVED_AT_PICKUP':
        return 'Arrived at pickup';
      case 'IN_TRANSIT':
        return 'Delivering to recipient';
      case 'ARRIVED_AT_DROPOFF':
        return 'Arrived at drop-off';
      default:
        return 'Driving to pickup';
    }
  }

  static String _statusMessage(String? status) {
    switch (status) {
      case 'ARRIVED_AT_PICKUP':
        return 'Check the package and scan the sender QR.';
      case 'IN_TRANSIT':
        return 'Follow the green route to the recipient.';
      case 'ARRIVED_AT_DROPOFF':
        return 'Verify the package and scan the recipient QR.';
      default:
        return 'Follow the blue route to the sender.';
    }
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
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
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(color: DriverColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DriverColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
