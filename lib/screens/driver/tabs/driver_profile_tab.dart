import 'package:flutter/material.dart';

import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/services/user_service.dart';
import '../../../features/auth/tokens/token_storage.dart';
import '../../../features/driver_registration/models/vehicle_type.dart';
import '../models/driver_request.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_map_widgets.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({
    super.key,
    required this.request,
    required this.onOpenMap,
  });

  final DriverRequest request;
  final VoidCallback onOpenMap;

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  final UserService _userService = UserService();
  UserProfile? _profile;
  bool _loadingProfile = true;

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
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final vehicleType = _profile?.vehicleType;
    final vehicleLabel = vehicleTypeLabel(vehicleType);
    final assignedVehicleCode = _profile?.assignedVehicleCode;
    final profileName =
        profile?.name.trim().isNotEmpty == true ? profile!.name : 'Driver';
    final profileEmail = profile?.email ?? 'Email not available';
    final profilePhone = profile?.phone?.trim().isNotEmpty == true
        ? profile!.phone!
        : 'Phone not available';
    final statusLabel = profile?.isActive == false ? 'Inactive' : 'Active';
    final accountLabel =
        profile?.role == 'driver' ? 'Driver account' : 'Account profile';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DriverHeroSection(
          subtitle: accountLabel,
          name: profileName,
          content: DriverStatusSummary(
            amount: assignedVehicleCode?.isNotEmpty == true
                ? assignedVehicleCode!
                : vehicleLabel,
            helperText: assignedVehicleCode?.isNotEmpty == true
                ? 'Assigned truck code'
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
                            child: Icon(
                              vehicleTypeIcon(vehicleType),
                              color: DriverColors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicleLabel,
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
                                      : 'Assigned vehicle for your delivery profile',
                                  style: const TextStyle(color: DriverColors.muted),
                                ),
                                if (assignedVehicleCode != null &&
                                    assignedVehicleCode.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Truck code: $assignedVehicleCode',
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
                        'Account details',
                        style: TextStyle(
                          color: DriverColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DriverStatLine(label: 'Name', value: profileName),
                      const SizedBox(height: 12),
                      DriverStatLine(label: 'Email', value: profileEmail),
                      const SizedBox(height: 12),
                      DriverStatLine(label: 'Phone', value: profilePhone),
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
                        backgroundColor:
                            widget.request.accent.withValues(alpha: 0.12),
                        child: Text(
                          widget.request.senderInitials,
                          style: TextStyle(
                            color: widget.request.accent,
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
                              'Next package: ${widget.request.title}',
                              style: const TextStyle(color: DriverColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const DriverStatusChip(label: 'Online'),
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
