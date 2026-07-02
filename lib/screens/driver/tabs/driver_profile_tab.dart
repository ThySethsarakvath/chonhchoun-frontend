import 'package:flutter/material.dart';

import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_button_widgets.dart';
import '../../../shared/widgets/driver_colors.dart';
import '../../../shared/widgets/driver_map_widgets.dart';
import '../../../shared/widgets/driver_request_widgets.dart';
import '../../../shared/widgets/driver_shell_widgets.dart';
import '../driver_provider.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/services/user_service.dart';
import '../../../features/auth/tokens/token_storage.dart';
import '../../../features/driver_registration/models/vehicle_type.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({
    super.key,
    required this.request,
    required this.onOpenMap,
    required this.driverState,
    required this.onRefreshDriverState,
  });

  final DriverRequest? request;
  final VoidCallback onOpenMap;
  final DriverStateSnapshot? driverState;
  final VoidCallback onRefreshDriverState;

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  final UserService _userService = UserService();
  UserProfile? _profile;
  bool _loadingProfile = true;
  bool _updatingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      final profile = await _userService.getMe(accessToken: accessToken);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
    widget.onRefreshDriverState();
  }

  Future<void> _updateAvailabilityStatus(String availabilityStatus) async {
    if (_updatingAvailability) return;
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      setState(() => _updatingAvailability = true);
      final profile = await _userService.updateDriverAvailabilityStatus(
        accessToken: accessToken,
        availabilityStatus: availabilityStatus,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      widget.onRefreshDriverState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability updated to ${availabilityStatus.replaceAll('_', ' ')}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingAvailability = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = DriverScope.of(context);
    final profile = _profile;
    final driverState = widget.driverState;
    final currentVehicle = driverState?.currentVehicle;
    final vehicleType = currentVehicle?.type ?? _profile?.vehicleType;
    final vehicleLabel = vehicleTypeLabel(vehicleType);
    final assignedVehicleCode =
        currentVehicle?.ownershipType == 'DRIVER_OWNED'
            ? null
            : currentVehicle?.code ?? _profile?.assignedVehicleCode;
    final profileName =
        profile?.name.trim().isNotEmpty == true
            ? profile!.name
            : (driverState?.profile.name.trim().isNotEmpty == true
                ? driverState!.profile.name
                : 'Driver');
    final profileEmail =
        profile?.email ?? driverState?.profile.email ?? 'Email not available';
    final profilePhone = profile?.phone?.trim().isNotEmpty == true
        ? profile!.phone!
        : (driverState?.profile.phone?.trim().isNotEmpty == true
            ? driverState!.profile.phone!
            : 'Phone not available');
    final effectiveRole = profile?.role ?? driverState?.profile.role;
    final statusLabel =
        driverState?.profile.availabilityStatus?.replaceAll('_', ' ') ??
            (profile?.isActive == false ? 'Inactive' : 'Active');
    final selectedAvailability =
        driverState?.profile.availabilityStatus ??
        profile?.availabilityStatus ??
        'OFFLINE';
    final accountLabel =
        effectiveRole == 'driver' ? 'Driver account' : 'Account profile';
    final categoryLabel = deliveryCategoryLabel(vehicleType);
    final operationLabel = deliveryOperationLabel(vehicleType);
    final routeLabel = deliveryRouteLabel(vehicleType);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: accountLabel,
          name: profileName,
          content: DriverStatusSummary(
            amount: currentVehicle != null
                ? _driverVehicleHeadline(currentVehicle)
                : assignedVehicleCode?.isNotEmpty == true
                    ? assignedVehicleCode!
                    : vehicleLabel,
            helperText: currentVehicle?.ownershipType == 'DRIVER_OWNED'
                ? 'Your own vehicle'
                : assignedVehicleCode?.isNotEmpty == true
                ? 'Current assigned vehicle'
                : 'Current vehicle',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _DriverProfileAvatar(profile: profile),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileName,
                                  style: const TextStyle(
                                    color: DriverColors.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profileEmail,
                                  style: const TextStyle(
                                    color: DriverColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profilePhone,
                                  style: const TextStyle(
                                    color: DriverColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DriverStatusChip(label: statusLabel),
                        ],
                      ),
                      const SizedBox(height: 18),
                      DriverStatLine(label: 'Role', value: 'Driver'),
                      const SizedBox(height: 12),
                      DriverStatLine(
                        label: 'Profile status',
                        value: _loadingProfile ? 'Loading...' : 'Ready',
                      ),
                      const SizedBox(height: 12),
                      DriverStatLine(label: 'Availability', value: statusLabel),
                      if (vehicleType != null && vehicleType.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DriverStatLine(label: 'Operation', value: categoryLabel),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DriverSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Availability Control',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Both you and the branch owner can update this status.',
                        style: TextStyle(color: DriverColors.muted),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedAvailability,
                        decoration: const InputDecoration(
                          labelText: 'Driver status',
                        ),
                        items: _driverAvailabilityOptions
                            .map(
                              (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.replaceAll('_', ' ')),
                              ),
                            )
                            .toList(),
                        onChanged: _updatingAvailability
                            ? null
                            : (value) {
                                if (value != null) {
                                  _updateAvailabilityStatus(value);
                                }
                              },
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
                                Text(
                                  vehicleType == null || vehicleType.isEmpty
                                      ? 'Vehicle type will appear here after branch approval.'
                                      : '$categoryLabel - $operationLabel',
                                  style: const TextStyle(
                                    color: DriverColors.muted,
                                  ),
                                ),
                                if (vehicleType != null && vehicleType.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Route: $routeLabel',
                                    style: const TextStyle(
                                      color: DriverColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (assignedVehicleCode != null &&
                                    assignedVehicleCode.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vehicle code: $assignedVehicleCode',
                                    style: const TextStyle(
                                      color: DriverColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (currentVehicle?.plateNumber?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Plate: ${currentVehicle!.plateNumber!}',
                                    style: const TextStyle(
                                      color: DriverColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (currentVehicle != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${currentVehicle.status.replaceAll('_', ' ')}',
                                    style: const TextStyle(
                                      color: DriverColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                          onPressed: widget.onOpenMap,
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
                        backgroundColor: (widget.request?.accent ?? DriverColors.blue).withValues(alpha: 0.12),
                        child: Text(
                          widget.request?.senderInitials ?? '?',
                          style: TextStyle(
                            color: widget.request?.accent ?? DriverColors.blue,
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

String _driverVehicleHeadline(DriverCurrentVehicle vehicle) {
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

class _DriverProfileAvatar extends StatelessWidget {
  final UserProfile? profile;

  const _DriverProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final initialsSource = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : 'Driver';
    final initials = initialsSource
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: 32,
      backgroundColor: DriverColors.blue.withValues(alpha: 0.10),
      backgroundImage:
          avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initials.isEmpty ? 'DR' : initials,
              style: const TextStyle(
                color: DriverColors.blue,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

const _driverAvailabilityOptions = [
  'AVAILABLE',
  'ON_BREAK',
  'UNAVAILABLE',
  'OFFLINE',
];
