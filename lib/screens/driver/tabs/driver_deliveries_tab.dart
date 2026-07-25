import 'package:flutter/material.dart';

import '../../../shared/data/driver_demo_data.dart';
import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_button_widgets.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';
import '../screens/driver_verification_scanner_screen.dart';
import '../widgets/express_driver_route_map.dart';

class DriverDeliveriesTab extends StatelessWidget {
  const DriverDeliveriesTab({
    super.key,
    required this.request,
    required this.onViewAll,
    required this.onSeeHistory,
    required this.onOpenDetail,
  });

  final DriverRequest? request;
  final VoidCallback onViewAll;
  final VoidCallback onSeeHistory;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    final currentReq = provider.currentDelivery;

    final deliveriesCount = provider.historyRequests.length;
    final totalMinutes = deliveriesCount * 25;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = "$hours Hours $mins Minutes";

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Weekly Overview',
          name: 'Driver',
          searchHint: 'Active delivery and route',
          content: DriverBalanceCard(
            amount: provider.balance.toStringAsFixed(2),
          ),
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
                      DriverStatLine(label: 'Time', value: timeStr),
                      const SizedBox(height: 18),
                      DriverStatLine(
                        label: 'Deliveries',
                        value: deliveriesCount.toString(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: DriverPrimaryButton(
                          label: 'See Details',
                          onPressed: onSeeHistory,
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
                      if (currentReq == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No active delivery right now.',
                              style: TextStyle(color: DriverColors.muted),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 430,
                          child: ExpressDriverRouteMap(
                            request: currentReq,
                            onFocus: onOpenDetail,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: DriverColors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _statusMessage(currentReq.status ?? 'ACCEPTED'),
                            style: const TextStyle(
                              color: DriverColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DriverHomeRequestPreview(
                          request: currentReq,
                          onTap: onOpenDetail,
                          showButtons: false,
                        ),
                        const SizedBox(height: 16),
                        if (currentReq.status == 'ARRIVED_AT_PICKUP' ||
                            currentReq.status == 'ARRIVED_AT_DROPOFF')
                          SizedBox(
                            width: double.infinity,
                            child: provider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : DriverPrimaryButton(
                                    label:
                                        currentReq.status == 'ARRIVED_AT_PICKUP'
                                        ? 'Scan Sender Pickup QR'
                                        : 'Scan Recipient Delivery QR',
                                    onPressed: () => _openVerificationScanner(
                                      context,
                                      provider,
                                      currentReq.status == 'ARRIVED_AT_PICKUP'
                                          ? 'Verify Sender Handoff'
                                          : 'Verify Recipient Delivery',
                                    ),
                                  ),
                          ),
                      ],
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

  String _statusMessage(String current) {
    switch (current) {
      case 'ACCEPTED':
        return 'Follow the blue route to the sender pickup.';
      case 'ARRIVED_AT_PICKUP':
        return 'You have arrived. Check the package, then scan the sender QR.';
      case 'IN_TRANSIT':
        return 'Follow the green route to the recipient.';
      case 'ARRIVED_AT_DROPOFF':
        return 'Check the recipient and package quantity, then scan their QR.';
      default:
        return 'Delivery status is updating.';
    }
  }

  Future<void> _openVerificationScanner(
    BuildContext context,
    DriverProvider provider,
    String title,
  ) async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DriverVerificationScannerScreen(
          title: title,
          onVerify: provider.verifyDeliveryQr,
        ),
      ),
    );
    if (!context.mounted) return;
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery QR verified successfully.')),
      );
    } else if (provider.lastError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastError!)));
    }
  }
}
