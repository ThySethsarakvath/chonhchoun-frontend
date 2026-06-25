import 'package:flutter/material.dart';

import '../../shared/models/driver_request.dart';
import 'screens/driver_map_detail_screen.dart';
import 'screens/driver_request_detail_screen.dart';
import 'screens/driver_requests_screen.dart';
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
  int _currentIndex = 0;
  late final DriverProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = DriverProvider()..init();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _openRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverRequestsScreen(
          requests: _provider.availableRequests,
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
          onAccept: () async {
            if (request.id != null) {
              final success = await _provider.acceptRequest(request.id!);
              if (success && mounted) {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery accepted successfully!')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to accept delivery.')),
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
                setState(() => _currentIndex = 1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery accepted successfully!')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return DriverBottomBar(
      selectedIndex: _currentIndex,
      onSelected: (index) => setState(() => _currentIndex = index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DriverScope(
      notifier: _provider,
      child: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final currentDelivery = _provider.currentDelivery;

          final tabs = [
            DriverHomeTab(
              requests: _provider.availableRequests,
              onViewAll: _openRequests,
              onOpenDetail: _openRequestDetail,
            ),
            DriverDeliveriesTab(
              request: currentDelivery,
              onViewAll: _openRequests,
              onSeeHistory: () {
                setState(() => _currentIndex = 2);
              },
              onOpenDetail: () {
                if (currentDelivery != null) {
                  _openRequestDetail(currentDelivery);
                }
              },
            ),
            DriverHistoryTab(
              onOpenDetail: _openRequestDetail,
            ),
            DriverProfileTab(
              request: currentDelivery,
              onOpenMap: () {
                if (currentDelivery != null) _openMapDetail(currentDelivery);
              },
            ),
          ];

          return Scaffold(
            backgroundColor: DriverColors.background,
            body: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
            bottomNavigationBar: _buildBottomNav(),
          );
        },
      ),
    );
  }
}
