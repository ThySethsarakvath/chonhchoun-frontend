import 'package:flutter/material.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/services/user_service.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../router/app_router.dart';
import 'data/driver_demo_data.dart';
import 'models/driver_request.dart';
import 'screens/driver_map_detail_screen.dart';
import 'screens/driver_request_detail_screen.dart';
import 'screens/driver_requests_screen.dart';
import 'tabs/driver_deliveries_tab.dart';
import 'tabs/driver_home_tab.dart';
import 'tabs/driver_profile_tab.dart';
import 'widgets/driver_colors.dart';
import 'widgets/driver_shell_widgets.dart';

class DriverWorkspaceScreen extends StatefulWidget {
  const DriverWorkspaceScreen({super.key});

  @override
  State<DriverWorkspaceScreen> createState() => _DriverWorkspaceScreenState();
}

class _DriverWorkspaceScreenState extends State<DriverWorkspaceScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  int _selectedIndex = 0;
  DriverStateSnapshot? _driverState;
  bool _loadingDriverState = true;
  bool _loggingOut = false;

  DriverRequest get _primaryRequest => driverRequests.first;

  @override
  void initState() {
    super.initState();
    _loadDriverState();
  }

  Future<void> _loadDriverState() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      final snapshot = await _userService.getDriverState(accessToken: accessToken);
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
        builder: (_) => DriverRequestsScreen(
          requests: driverRequests,
          onOpenDetail: _openRequestDetail,
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
        ),
      ),
    );
  }

  void _openMapDetail(DriverRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverMapDetailScreen(request: request),
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
    return Scaffold(
      backgroundColor: DriverColors.surface,
      appBar: AppBar(
        backgroundColor: DriverColors.surface,
        elevation: 0,
        title: const Text(
          'Driver Portal',
          style: TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _loggingOut ? null : _confirmLogout,
            icon: _loggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(_loggingOut ? 'Signing out...' : 'Logout'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(width: 12),
        ],
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
          ),
          DriverDeliveriesTab(
            request: _primaryRequest,
            onViewAll: _openRequests,
            onOpenDetail: () => _openRequestDetail(_primaryRequest),
          ),
          DriverProfileTab(
            request: _primaryRequest,
            onOpenMap: () => _openMapDetail(_primaryRequest),
            driverState: _driverState,
            onRefreshDriverState: _loadDriverState,
          ),
        ],
      ),
    );
  }
}
