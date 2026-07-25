import 'package:flutter/material.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/services/user_service.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../router/app_router.dart';
import 'data/driver_demo_data.dart';
import '../../shared/models/driver_request.dart';
import 'screens/driver_map_detail_screen.dart';
import 'screens/driver_active_delivery_map_screen.dart';
import 'screens/driver_history_detail_screen.dart';
import 'screens/driver_request_detail_screen.dart';
import 'screens/driver_requests_screen.dart';
import 'tabs/driver_branch_logistics_tab.dart';
import 'tabs/driver_deliveries_tab.dart';
import 'tabs/driver_home_tab.dart';
import 'tabs/driver_history_tab.dart';
import 'tabs/driver_profile_tab.dart';
import 'driver_provider.dart';
import '../../shared/widgets/driver_colors.dart';
import '../../shared/widgets/driver_shell_widgets.dart';

class DriverWorkspaceScreen extends StatefulWidget {
  const DriverWorkspaceScreen({super.key});

  @override
  State<DriverWorkspaceScreen> createState() => _DriverWorkspaceScreenState();
}

class _DriverWorkspaceScreenState extends State<DriverWorkspaceScreen> {
  late DriverProvider _provider;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  int _selectedIndex = 0;
  DriverStateSnapshot? _driverState;
  bool _loadingDriverState = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _provider = DriverProvider()..init();
    _loadDriverState();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _loadDriverState() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      final snapshot = await _userService.getDriverState(
        accessToken: accessToken,
      );
      if (!mounted) return;
      setState(() => _driverState = snapshot);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingDriverState = false);
      }
    }
  }

  void _openRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverIdentityScope(
          avatarUrl: _driverState?.profile.avatarUrl,
          child: DriverRequestsScreen(
            requests: _provider.availableRequests,
            onOpenDetail: _openRequestDetail,
          ),
        ),
      ),
    );
  }

  void _openRequestDetail(DriverRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverRequestDetailScreen(
          request: request,
          onOpenMap: () => _openMapDetail(request),
          onAccept: () async {
            if (request.id != null) {
              final success = await _provider.acceptRequest(request.id!);
              if (success && mounted) {
                Navigator.of(context).pop();
                setState(() => _selectedIndex = 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery accepted successfully!'),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _provider.lastError ?? 'Failed to accept delivery.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _openMapDetail(DriverRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverMapDetailScreen(
          request: request,
          onAccept: () async {
            if (request.id != null) {
              final success = await _provider.acceptRequest(request.id!);
              if (success && mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                setState(() => _selectedIndex = 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery accepted successfully!'),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _provider.lastError ?? 'Failed to accept delivery.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _openActiveDeliveryMap() {
    if (_provider.currentDelivery == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverActiveDeliveryMapScreen(provider: _provider),
      ),
    );
  }

  void _openHistoryDetail(DriverRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverHistoryDetailScreen(request: request),
      ),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        await _authService.logout(accessToken: accessToken);
      }
    } catch (_) {
      // Clear local session even if backend logout fails.
    } finally {
      await TokenStorage.clearTokens();

      if (mounted) {
        setState(() => _loggingOut = false);
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    }
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to sign out and go back to login?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryRequest = driverRequests.isNotEmpty
        ? driverRequests.first
        : null;
    final vehicleType =
        _driverState?.currentVehicle?.type ?? _driverState?.profile.vehicleType;
    final isTruckDriver =
        vehicleType == 'TRUCK' || vehicleType == 'TRUCK_LARGE';

    return DriverIdentityScope(
      avatarUrl: _driverState?.profile.avatarUrl,
      child: DriverScope(
        notifier: _provider,
        child: Scaffold(
          backgroundColor: DriverColors.surface,
          drawer: _DriverPortalDrawer(
            selectedIndex: _selectedIndex,
            driverName: _driverState?.profile.name ?? 'Driver',
            avatarUrl: _driverState?.profile.avatarUrl,
            onSelected: (index) {
              Navigator.of(context).pop();
              setState(() => _selectedIndex = index);
            },
            onLogout: () {
              Navigator.of(context).pop();
              _confirmLogout();
            },
          ),
          bottomNavigationBar: DriverBottomBar(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DriverHomeTab(
                requests: driverRequests,
                onViewAll: _openRequests,
                onOpenDetail: _openRequestDetail,
                driverState: _driverState,
                loadingDriverState: _loadingDriverState,
                onOpenActive: () {
                  if (_provider.currentDelivery != null) {
                    _openActiveDeliveryMap();
                  } else {
                    setState(() => _selectedIndex = 1);
                  }
                },
                onOpenProfile: () => setState(() => _selectedIndex = 3),
              ),
              if (isTruckDriver)
                const DriverBranchLogisticsTab()
              else
                DriverDeliveriesTab(
                  request: _provider.currentDelivery,
                  onViewAll: _openRequests,
                  onSeeHistory: () => setState(() => _selectedIndex = 2),
                  onOpenDetail: () {
                    _openActiveDeliveryMap();
                  },
                ),
              DriverHistoryTab(onOpenDetail: _openHistoryDetail),
              DriverProfileTab(
                request: primaryRequest,
                onOpenMap: () {
                  if (primaryRequest != null) {
                    _openMapDetail(primaryRequest);
                  }
                },
                driverState: _driverState,
                onRefreshDriverState: _loadDriverState,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverPortalDrawer extends StatelessWidget {
  const _DriverPortalDrawer({
    required this.selectedIndex,
    required this.driverName,
    required this.avatarUrl,
    required this.onSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final String driverName;
  final String? avatarUrl;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.home_rounded, 'Home'),
      (Icons.route_rounded, 'Deliveries'),
      (Icons.history_rounded, 'History'),
      (Icons.person_rounded, 'Profile'),
    ];
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              22,
              MediaQuery.paddingOf(context).top + 28,
              22,
              26,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [DriverColors.blueDark, DriverColors.blue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: avatarUrl?.trim().isNotEmpty == true
                        ? Image.network(
                            avatarUrl!.trim(),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.delivery_dining_rounded,
                              color: DriverColors.blue,
                              size: 34,
                            ),
                          )
                        : const Icon(
                            Icons.delivery_dining_rounded,
                            color: DriverColors.blue,
                            size: 34,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'ChonhChoun Driver',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < destinations.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                selected: selectedIndex == index,
                selectedColor: DriverColors.blueDark,
                selectedTileColor: DriverColors.softBlue.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(destinations[index].$1),
                title: Text(
                  destinations[index].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => onSelected(index),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              textColor: DriverColors.danger,
              iconColor: DriverColors.danger,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
