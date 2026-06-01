import 'package:flutter/material.dart';

import '../../shared/data/driver_demo_data.dart';
import '../../shared/models/driver_request.dart';
import 'screens/driver_map_detail_screen.dart';
import 'screens/driver_request_detail_screen.dart';
import 'screens/driver_requests_screen.dart';
import 'tabs/driver_deliveries_tab.dart';
import 'tabs/driver_home_tab.dart';
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

  List<Widget> get _tabs => [
        DriverHomeTab(
          requests: driverRequests,
          onViewAll: _openRequests,
          onOpenDetail: _openRequestDetail,
        ),
        DriverDeliveriesTab(
          request: _primaryRequest,
          onViewAll: _openRequests,
          onOpenDetail: () => _openRequestDetail(_primaryRequest),
        ),
        // Placeholder for activity tab (not implemented yet)
        const Center(child: Text('Activity Tab', style: TextStyle(color: DriverColors.text))),
        DriverProfileTab(
          request: _primaryRequest,
          onOpenMap: () => _openMapDetail(_primaryRequest),
        ),
      ];

  DriverRequest get _primaryRequest => driverRequests.first;

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
      child: Scaffold(
        backgroundColor: DriverColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}
