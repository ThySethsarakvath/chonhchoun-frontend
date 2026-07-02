import 'package:flutter/material.dart';

import '../../../features/auth/models/user_model.dart';
import '../../../features/driver_registration/models/vehicle_type.dart';
import '../data/driver_demo_data.dart';
import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';

class DriverHomeTab extends StatelessWidget {
  const DriverHomeTab({
    super.key,
    required this.requests,
    required this.onViewAll,
    required this.onOpenDetail,
    required this.driverState,
    required this.loadingDriverState,
  });

  final List<DriverRequest> requests;
  final VoidCallback onViewAll;
  final ValueChanged<DriverRequest> onOpenDetail;
  final DriverStateSnapshot? driverState;
  final bool loadingDriverState;

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    final availableCount = provider.availableRequests.length;
    final currentVehicle = driverState?.currentVehicle;
    final driverName = driverState?.profile.name.trim().isNotEmpty == true
        ? driverState!.profile.name
        : driverDisplayName;
    final heroAmount = loadingDriverState
        ? 'Loading...'
        : currentVehicle != null
            ? _vehicleHeadline(currentVehicle)
            : 'No vehicle';
    final heroHelper = loadingDriverState
        ? 'Checking assignment'
        : currentVehicle != null
            ? '${deliveryCategoryLabel(currentVehicle.type)} | ${currentVehicle.status.replaceAll('_', ' ')}'
            : 'No active vehicle assigned';

    return RefreshIndicator(
      onRefresh: () async {
        if (provider.isOnline) {
          await provider.fetchAvailableRequests();
        }
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DriverHeroSection(
            subtitle: provider.isOnline ? 'Online' : 'Offline',
            name: driverName,
            content: DriverStatusSummary(
              amount: heroAmount,
              helperText: heroHelper,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  DriverSurfaceCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver Status',
                              style: TextStyle(
                                color: DriverColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isOnline ? 'Receiving requests...' : 'Offline (No requests)',
                              style: const TextStyle(
                                color: DriverColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        provider.isLoading
                            ? const CircularProgressIndicator()
                            : Switch(
                                value: provider.isOnline,
                                activeThumbColor: DriverColors.blue,
                                onChanged: (val) {
                                  provider.toggleOnline();
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (provider.isOnline) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Available Requests ($availableCount)',
                            style: const TextStyle(
                              color: DriverColors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (provider.availableRequests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No available requests in your area.',
                            style: TextStyle(color: DriverColors.muted),
                          ),
                        ),
                      )
                    else
                      ...provider.availableRequests.map((req) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DriverHomeRequestPreview(
                            request: req,
                            onTap: () => onOpenDetail(req),
                          ),
                        );
                      }),
                  ] else ...[
                    DriverSurfaceCard(
                      child: Row(
                        children: [
                          Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: DriverColors.blue.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: DriverColors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Go online to receive delivery requests',
                              style: TextStyle(
                                color: DriverColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _vehicleHeadline(DriverCurrentVehicle vehicle) {
  if (vehicle.ownershipType == 'DRIVER_OWNED') {
    if (vehicle.plateNumber?.isNotEmpty == true) {
      return vehicle.plateNumber!;
    }
    if (vehicle.type == driverOwnMotorcycleType) {
      return 'Own motorbike';
    }
    return 'Own vehicle';
  }
  if (vehicle.plateNumber?.isNotEmpty == true) {
    return vehicle.plateNumber!;
  }
  return vehicle.code;
}
