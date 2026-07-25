import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
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
              title: const Text(
                'Delivery completed',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: DriverColors.success.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: DriverColors.success,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text(
                            'Delivery completed',
                            style: TextStyle(
                              color: DriverColors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'The package handoff was verified successfully.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: DriverColors.muted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('Return to dashboard'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DriverColors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.customerContentMaxWidth,
                      ),
                      child: Material(
                        color: Colors.white,
                        elevation: 5,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: DriverColors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _statusIcon(request.status),
                                  color: DriverColors.blue,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  label:
                                      'Delivery status: ${_statusTitle(request.status)}',
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        _statusMessage(request.status),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: DriverColors.muted,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: DriverColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: DriverColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.all(AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.customerContentMaxWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.standard,
                          child: canScan
                              ? Padding(
                                  key: ValueKey(request.status),
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: FilledButton.icon(
                                      onPressed: provider.isLoading
                                          ? null
                                          : () => _openScanner(
                                              context,
                                              request.status!,
                                            ),
                                      icon: provider.isLoading
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.qr_code_scanner_rounded,
                                            ),
                                      label: Text(
                                        request.status == 'ARRIVED_AT_PICKUP'
                                            ? 'Scan sender pickup QR'
                                            : 'Scan recipient completion QR',
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: DriverColors.blue,
                                        foregroundColor: Colors.white,
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Material(
                          color: Colors.white,
                          elevation: 7,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RouteLine(
                                  icon: Icons.inventory_2_rounded,
                                  color: DriverColors.blue,
                                  label: 'Pickup',
                                  value: request.pickup,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _RouteLine(
                                  icon: Icons.location_on_rounded,
                                  color: DriverColors.danger,
                                  label: 'Drop-off',
                                  value: request.dropOff,
                                ),
                                const Divider(height: AppSpacing.xl),
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
                                    const SizedBox(width: AppSpacing.sm),
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
      if (status == 'ARRIVED_AT_DROPOFF') {
        await _showCompletionDialog(context);
        return;
      }
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

  Future<void> _showCompletionDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: DriverColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: DriverColors.success,
            size: 40,
          ),
        ),
        title: const Text(
          'Delivery completed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'The recipient QR was verified and the delivery has been added to your history.',
          textAlign: TextAlign.center,
          style: TextStyle(color: DriverColors.muted, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.maybePop(context);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('Return to dashboard'),
            style: FilledButton.styleFrom(
              backgroundColor: DriverColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 50),
            ),
          ),
        ],
      ),
    );
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
