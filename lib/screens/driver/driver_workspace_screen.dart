import 'package:flutter/material.dart';

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
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.surface,
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
          ),
          DriverDeliveriesTab(
            request: _primaryRequest,
            onViewAll: _openRequests,
            onOpenDetail: () => _openRequestDetail(_primaryRequest),
          ),
          DriverProfileTab(
            request: _primaryRequest,
            onOpenMap: () => _openMapDetail(_primaryRequest),
          ),
        ],
      ),
    );
  }
}
