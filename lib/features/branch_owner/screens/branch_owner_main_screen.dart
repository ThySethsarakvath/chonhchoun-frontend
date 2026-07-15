import 'package:flutter/material.dart';

import '../../../router/app_router.dart';
import '../../admin_management/models/branch_model.dart';
import '../../admin_management/services/branch_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../../driver_registration/models/driver_application_model.dart';
import '../../driver_registration/models/driver_management_model.dart';
import '../../driver_registration/services/driver_application_service.dart';
import 'branch_driver_agents_screen.dart';
import 'branch_information_screen.dart';
import 'branch_logistics_list_screen.dart';
import 'branch_owner_overview_screen.dart';
import 'branch_sales_screen.dart';
import 'branch_wallet_screen.dart';
import '../../dispatch_receipt/screens/dispatch_receipt_main_screen.dart';
import '../widgets/branch_owner_content_widgets.dart';
import '../widgets/branch_owner_sidebar.dart';

class BranchOwnerMainScreen extends StatefulWidget {
  const BranchOwnerMainScreen({super.key});

  @override
  State<BranchOwnerMainScreen> createState() => _BranchOwnerMainScreenState();
}

class _BranchOwnerMainScreenState extends State<BranchOwnerMainScreen> {
  final AuthService _authService = AuthService();
  final BranchService _branchService = BranchService();
  final DriverApplicationService _driverApplicationService =
      DriverApplicationService();

  int _selectedIndex = 0;
  bool _loggingOut = false;
  bool _branchInfoLoading = true;
  String? _branchInfoError;
  Branch? _ownedBranch;
  bool _driverManagementLoading = true;
  String? _driverManagementError;
  BranchDriverManagementOverview? _driverManagementOverview;
  bool _driverRequestsLoading = true;
  String? _driverRequestsError;
  List<DriverApplication> _driverApplications = const [];

  @override
  void initState() {
    super.initState();
    _loadBranchOwnerData();
  }

  Future<void> _loadBranchOwnerData() async {
    setState(() {
      _branchInfoLoading = true;
      _branchInfoError = null;
      _driverManagementLoading = true;
      _driverManagementError = null;
      _driverRequestsLoading = true;
      _driverRequestsError = null;
    });

    try {
      final results = await Future.wait([
        _branchService.getMyBranch(),
        _driverApplicationService.getBranchOwnerManagementOverview(),
        _driverApplicationService.getBranchOwnerApplications(),
      ]);
      final ownedBranch = results[0] as Branch;
      final driverManagement =
          results[1] as BranchDriverManagementOverview;
      final driverApplications = results[2] as List<DriverApplication>;

      if (!mounted) return;
      setState(() {
        _ownedBranch = ownedBranch;
        _branchInfoLoading = false;
        _driverManagementOverview = driverManagement;
        _driverManagementLoading = false;
        _driverApplications = driverApplications;
        _driverRequestsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _branchInfoLoading = false;
        _branchInfoError = e.toString().replaceFirst('Exception: ', '');
        _driverManagementLoading = false;
        _driverManagementError = e.toString().replaceFirst('Exception: ', '');
        _driverRequestsLoading = false;
        _driverRequestsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
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

  String get _salesTodayLabel => _ownedBranch == null ? '-' : '\$0';

  String get _driverAgentCountLabel =>
      _ownedBranch == null ? '-' : 'Handled in logistics';

  String get _pendingRequestsLabel => _ownedBranch == null
      ? '-'
      : '${_driverApplications.where((application) => application.status == 'pending').length} pending';

  @override
  Widget build(BuildContext context) {
    final views = <_BranchOwnerSectionData>[
      _BranchOwnerSectionData(
        title: 'Branch Owner Portal',
        content: BranchOwnerOverviewScreen(
          salesTodayLabel: _salesTodayLabel,
          driverAgentCountLabel: _driverAgentCountLabel,
          pendingRequestsLabel: _pendingRequestsLabel,
        ),
      ),
      _BranchOwnerSectionData(
        title: 'Branch Information',
        content: BranchInformationScreen(
          branchInfoContent: _buildBranchInfoContent(),
        ),
      ),
      _BranchOwnerSectionData(
        title: 'Driver Management',
        content: BranchDriverAgentsScreen(
          loading: _driverManagementLoading,
          error: _driverManagementError,
          overview: _driverManagementOverview,
          onRefresh: _loadBranchOwnerData,
          onUpdateDriverManagement: _updateDriverManagement,
          onAssignVehicle: _assignVehicleToDriver,
          onUnassignVehicle: _unassignVehicleFromDriver,
          onDeactivateDriver: _deactivateDriver,
        ),
      ),
      _BranchOwnerSectionData(
        title: 'Package Management',
        content: BranchSalesScreen(
          ownedBranch: _ownedBranch,
        ),
      ),
      _BranchOwnerSectionData(
        title: 'Branch Logistics',
        content: BranchLogisticsListScreen(
          ownedBranch: _ownedBranch,
        ),
      ),
      _BranchOwnerSectionData(
        title: 'Branch Wallet',
        content: const BranchWalletScreen(),
      ),
      _BranchOwnerSectionData(
        title: 'Dispatch Receipts',
        content: const DispatchReceiptMainScreen(),
      ),
    ];

    final currentSection = views[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        title: Text(
          currentSection.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BranchOwnerSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: currentSection.content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfoContent() {
    if (_branchInfoLoading) {
      return const BranchOwnerLoadingCard(
        message: 'Loading your branch information...',
      );
    }

    if (_branchInfoError != null) {
      return BranchOwnerMessageCard(
        title: 'Unable to load branch information',
        description: _branchInfoError!,
        actionLabel: 'Try again',
        onAction: _loadBranchOwnerData,
      );
    }

    if (_ownedBranch == null) {
      return const BranchOwnerMessageCard(
        title: 'No branch assigned yet',
        description:
            'Your account is active, but no branch could be matched to this branch-owner profile yet. Please contact admin to confirm branch assignment.',
      );
    }

    final branch = _ownedBranch!;
    return BranchOwnerFeatureListCard(
      title: 'Current branch details',
      items: [
        'Branch number: ${branch.branchNumber?.toString() ?? '-'}',
        'Phone: ${branch.phone ?? branch.ownerPhone ?? '-'}',
        'Address: ${branch.address ?? '-'}',
        'Description: ${_displayText(branch.description)}',
        'Status: ${branch.status ?? (branch.isActive ? 'active' : 'inactive')}',
        'Owner name: ${branch.ownerName ?? '-'}',
      ],
    );
  }

  String _displayText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }

  Future<void> _updateDriverManagement(
    ManagedDriver driver, {
    required String availabilityStatus,
    String? licenseNumber,
    double? maxLoadWeightKg,
    int? maxPackageCount,
  }) async {
    try {
      await _driverApplicationService.updateBranchDriverManagement(
        driver.id,
        availabilityStatus: availabilityStatus,
        licenseNumber: licenseNumber,
        maxLoadWeightKg: maxLoadWeightKg,
        maxPackageCount: maxPackageCount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${driver.name} updated successfully.')),
      );
      await _loadBranchOwnerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _assignVehicleToDriver(
    ManagedDriver driver,
    ManagedVehicle vehicle,
  ) async {
    try {
      await _driverApplicationService.assignVehicleToDriver(
        driver.id,
        vehicleId: vehicle.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vehicle.code} assigned to ${driver.name}.')),
      );
      await _loadBranchOwnerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _unassignVehicleFromDriver(ManagedDriver driver) async {
    try {
      await _driverApplicationService.unassignVehicleFromDriver(driver.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle unassigned from ${driver.name}.')),
      );
      await _loadBranchOwnerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _deactivateDriver(ManagedDriver driver) async {
    try {
      await _driverApplicationService.deactivateBranchDriver(driver.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${driver.name} removed from active roster.')),
      );
      await _loadBranchOwnerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }
}

class _BranchOwnerSectionData {
  final String title;
  final Widget content;

  const _BranchOwnerSectionData({
    required this.title,
    required this.content,
  });
}
