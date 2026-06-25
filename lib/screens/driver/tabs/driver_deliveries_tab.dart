import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/data/driver_demo_data.dart';
import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_button_widgets.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';

class DriverDeliveriesTab extends StatefulWidget {
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
  State<DriverDeliveriesTab> createState() => _DriverDeliveriesTabState();
}

class _DriverDeliveriesTabState extends State<DriverDeliveriesTab> {
  bool _localLoading = false;

  Future<void> _handleStatusTransition(DriverProvider provider, String nextStatus) async {
    if (_localLoading || provider.isLoading) return; // Prevent double click

    setState(() {
      _localLoading = true;
    });

    try {
      if (nextStatus == 'DELIVERED') {
        // Prompt for PoD image using camera
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proof of Delivery photo is required.')),
            );
          }
          setState(() {
            _localLoading = false;
          });
          return;
        }

        // Upload PoD image
        final File file = File(image.path);
        final String? url = await provider.uploadFile(file);

        if (url == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload Proof of Delivery photo. Please try again.')),
            );
          }
          setState(() {
            _localLoading = false;
          });
          return;
        }

        // Complete delivery with PoD image
        final success = await provider.updateDeliveryStatus(nextStatus, podImage: url);
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to complete delivery status update.')),
          );
        }
      } else {
        final success = await provider.updateDeliveryStatus(nextStatus);
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update status.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    final currentReq = provider.currentDelivery;
    
    final deliveriesCount = provider.historyRequests.length;
    final totalMinutes = deliveriesCount * 25;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = "$hours Hours $mins Minutes";

    final showSpinner = _localLoading || provider.isLoading;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: 'Weekly Overview',
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
                      DriverStatLine(
                        label: 'Time',
                        value: timeStr,
                      ),
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
                          onPressed: widget.onSeeHistory,
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
                        DriverHomeRequestPreview(
                          request: currentReq,
                          onTap: widget.onOpenDetail,
                          showButtons: false,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: showSpinner
                              ? const Center(child: CircularProgressIndicator())
                              : DriverPrimaryButton(
                                  label: _getNextStatusLabel(currentReq.status ?? 'ACCEPTED'),
                                  onPressed: () {
                                    final next = _getNextStatus(currentReq.status ?? 'ACCEPTED');
                                    if (next != null) {
                                      _handleStatusTransition(provider, next);
                                    }
                                  },
                                ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onViewAll,
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

  String _getNextStatusLabel(String current) {
    switch (current) {
      case 'ACCEPTED': return 'Mark as Picked Up';
      case 'PICKED_UP': return 'Mark as In Transit';
      case 'IN_TRANSIT': return 'Mark as Delivered';
      default: return 'Finished';
    }
  }

  String? _getNextStatus(String current) {
    switch (current) {
      case 'ACCEPTED': return 'PICKED_UP';
      case 'PICKED_UP': return 'IN_TRANSIT';
      case 'IN_TRANSIT': return 'DELIVERED';
      default: return null;
    }
  }
}
