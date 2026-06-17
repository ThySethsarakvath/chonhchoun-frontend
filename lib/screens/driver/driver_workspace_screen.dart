import 'package:flutter/material.dart';

import 'screens/driver_earnings_screen.dart';
import 'tabs/driver_deliveries_tab.dart';
import 'tabs/driver_home_tab.dart';
import 'tabs/driver_profile_tab.dart';
import 'tabs/driver_route_tab.dart';
import 'widgets/driver_colors.dart';
import 'widgets/driver_shell_widgets.dart';
import '../../features/auth/services/user_service.dart';
import '../../features/auth/tokens/token_storage.dart';
import '../../features/chat/models/conversation.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/services/conversation_service.dart';

class DriverWorkspaceScreen extends StatefulWidget {
  const DriverWorkspaceScreen({super.key});

  @override
  State<DriverWorkspaceScreen> createState() => _DriverWorkspaceScreenState();
}

class _DriverWorkspaceScreenState extends State<DriverWorkspaceScreen> {
  int _selectedIndex = 0;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _loadDriverId();
  }

  Future<void> _loadDriverId() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    try {
      final me = await UserService().getMe(accessToken: token);
      if (mounted) setState(() => _driverId = me.id);
    } catch (_) {}
  }

  void _openChats() {
    final id = _driverId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationsScreen(
          currentUserId: id,
          showAppBar: true,
          loader: () async {
            final token = await TokenStorage.getAccessToken();
            if (token == null) return <Conversation>[];
            return ConversationService().driverConversations(token);
          },
        ),
      ),
    );
  }

  void _openEarnings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DriverEarningsScreen(),
      ),
    );
  }

  void _openRoute() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
      floatingActionButton: _driverId == null
          ? null
          : FloatingActionButton(
              backgroundColor: DriverColors.blue,
              onPressed: _openChats,
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            ),
      bottomNavigationBar: DriverBottomBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DriverHomeTab(
            onOpenEarnings: _openEarnings,
            onOpenRoute: _openRoute,
          ),
          const DriverRouteTab(),
          DriverDeliveriesTab(
            onOpenEarnings: _openEarnings,
          ),
          DriverProfileTab(
            onOpenRoute: _openRoute,
          ),
        ],
      ),
    );
  }
}
