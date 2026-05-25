import 'package:flutter/material.dart';

import '../../admin_management/screens/admin_overview_screen.dart';
import '../../admin_management/screens/branch_screen.dart';
import '../../admin_management/screens/admin_user_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../../../router/app_router.dart';
import '../widgets/admin_sidebar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();
  bool _loggingOut = false;

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
        content: const Text('Do you want to sign out and return to login?'),
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
    final adminViews = <Widget>[
      const AdminOverviewScreen(),
      const BranchScreen(),
      const AdminUserScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        title: const Text(
          'Admin Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
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
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: adminViews[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
