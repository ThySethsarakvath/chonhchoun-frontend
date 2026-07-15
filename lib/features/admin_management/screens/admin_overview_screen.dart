import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../models/admin_user_model.dart';
import '../models/branch_model.dart';
import '../models/company_wallet_model.dart';
import '../models/revenue_sharing_model.dart';
import '../services/admin_user_service.dart';
import '../services/branch_service.dart';
import '../services/company_wallet_service.dart';
import '../services/revenue_sharing_service.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  static const String _defaultLogoPath = 'assets/images/bluelogo.png';

  final _userService = AdminUserService();
  final _branchService = BranchService();
  final _revenueSharingService = RevenueSharingService();
  final _companyWalletService = CompanyWalletService();

  List<AdminUser> _users = [];
  List<Branch> _branches = [];
  RevenueSharingConfig? _revenueSharingConfig;
  CompanyWalletSummary? _companyWalletSummary;
  List<CompanyWalletTransaction> _companyTransactions = const [];
  bool _loading = true;
  String? _loadError;
  String? _companyFinanceError;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final users = await _userService.getUsers();
      final branches = await _branchService.getAllBranches();
      RevenueSharingConfig? revenueSharingConfig;
      String? revenueSharingError;
      CompanyWalletSummary? companyWalletSummary;
      List<CompanyWalletTransaction> companyTransactions = const [];
      String? companyFinanceError;

      try {
        revenueSharingConfig = await _revenueSharingService.getCurrentConfig();
      } on ApiException catch (e) {
        revenueSharingError = e.message;
      } catch (e) {
        revenueSharingError = e.toString().replaceFirst('Exception: ', '');
      }

      try {
        final monthRange = _selectedMonthRange;
        final financeResults = await Future.wait([
          _companyWalletService.getCompanyWalletSummary(),
          _companyWalletService.getCompanyTransactions(
            dateFrom: monthRange.start.toIso8601String(),
            dateTo: monthRange.end.toIso8601String(),
          ),
        ]);
        companyWalletSummary = financeResults[0] as CompanyWalletSummary;
        companyTransactions =
            financeResults[1] as List<CompanyWalletTransaction>;
      } on ApiException catch (e) {
        companyFinanceError = e.message;
      } catch (e) {
        companyFinanceError = e.toString().replaceFirst('Exception: ', '');
      }

      if (!mounted) return;

      setState(() {
        _users = users;
        _branches = branches;
        _revenueSharingConfig = revenueSharingConfig;
        _companyWalletSummary = companyWalletSummary;
        _companyTransactions = companyTransactions;
        _loadError = revenueSharingError;
        _companyFinanceError = companyFinanceError;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  _MonthRange get _selectedMonthRange {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    ).subtract(const Duration(milliseconds: 1));
    return _MonthRange(start: start, end: end);
  }

  String _formatMonthLabel(DateTime value) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[value.month - 1]} ${value.year}';
  }

  List<DateTime> get _availableMonths {
    final months = <DateTime>[];
    final now = DateTime.now();
    for (var offset = 0; offset < 12; offset += 1) {
      months.add(DateTime(now.year, now.month - offset));
    }
    return months;
  }

  Future<void> _changeMonth(DateTime month) async {
    setState(() => _selectedMonth = DateTime(month.year, month.month));
    await _loadDashboard();
  }

  _AdminRevenueMetrics get _adminRevenueMetrics {
    final totals = <String, double>{};
    var grossRevenue = 0.0;
    var companyIncome = 0.0;
    var branchIncome = 0.0;

    for (final transaction in _companyTransactions) {
      if (transaction.status != 'POSTED') continue;

      final sign = transaction.type == 'DEBIT' ? -1.0 : 1.0;
      companyIncome += transaction.amount * sign;

      if (transaction.totalPrice != null) {
        grossRevenue += transaction.totalPrice! * sign;
        branchIncome += (transaction.totalPrice! - transaction.amount) * sign;
      }

      final ticketKey = transaction.ticketNumber?.trim();
      if (ticketKey != null && ticketKey.isNotEmpty) {
        totals[ticketKey] = (totals[ticketKey] ?? 0) + sign;
      }
    }

    final completedDeliveries = totals.values.where((value) => value > 0).length;

    return _AdminRevenueMetrics(
      grossRevenue: grossRevenue,
      companyIncome: companyIncome,
      branchIncome: branchIncome,
      completedDeliveries: completedDeliveries,
    );
  }

  String _money(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  String _dateTimeLabel(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  Future<void> _showRevenueSharingDialog() async {
    final current = _revenueSharingConfig;
    if (current == null) return;

    final senderCtrl =
        TextEditingController(text: current.senderBranchPercent.toString());
    final receiverCtrl =
        TextEditingController(text: current.receiverBranchPercent.toString());
    final companyCtrl =
        TextEditingController(text: current.companyPercent.toString());
    final noteCtrl = TextEditingController(text: current.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Revenue Sharing'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: senderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sender branch %',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: receiverCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Receiver branch %',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Company/admin %',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Version note',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final sender = int.tryParse(senderCtrl.text.trim()) ?? -1;
              final receiver = int.tryParse(receiverCtrl.text.trim()) ?? -1;
              final company = int.tryParse(companyCtrl.text.trim()) ?? -1;
              if (sender + receiver + company != 100) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revenue sharing must total 100%.'),
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                );
                return;
              }

              try {
                await _revenueSharingService.createVersion(
                  RevenueSharingUpdateRequest(
                    senderBranchPercent: sender,
                    receiverBranchPercent: receiver,
                    companyPercent: company,
                    note: noteCtrl.text.trim(),
                  ),
                );
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadDashboard();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revenue sharing rule updated successfully.'),
                  ),
                );
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message),
                    backgroundColor: const Color(0xFFD32F2F),
                  ),
                );
              }
            },
            child: const Text('Save version'),
          ),
        ],
      ),
    );
  }

  String _resolvedLogoPath(Branch branch) {
    final logoUrl = branch.logoUrl;
    if (logoUrl == null ||
        logoUrl.isEmpty ||
        logoUrl == 'assets/images/logo.png') {
      return _defaultLogoPath;
    }
    return logoUrl;
  }

  int get _branchOwnerCount =>
      _users.where((user) => user.role == 'branch_owner').length;

  int get _activeBranchCount => _branches
      .where(
        (branch) =>
            branch.status == 'active' ||
            (branch.status == null && branch.isActive),
      )
      .length;

  List<Branch> get _mappableBranches => _branches
      .where((branch) => branch.lat != null && branch.lng != null)
      .toList();

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${value.day.toString().padLeft(2, '0')} ${monthNames[value.month - 1]} ${value.year}';
  }

  String _buildTooltipMessage(Branch branch) {
    final branchLabel = branch.branchNumber != null
        ? 'Branch ${branch.branchNumber}'
        : branch.name;
    return [
      branchLabel,
      'Owner: ${branch.ownerName ?? 'Not assigned'}',
      'Owner since: ${_formatDate(branch.branchOwnerSince)}',
      'Address: ${branch.address ?? '-'}',
      'Phone: ${branch.phone ?? branch.ownerPhone ?? '-'}',
    ].join('\n');
  }

  void _showBranchDetails(Branch branch) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PopupLogo(
                  logoPath: _resolvedLogoPath(branch),
                  defaultLogoPath: _defaultLogoPath,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branch.ownerName ?? 'Branch owner not assigned',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _OverviewDetailRow(
              label: 'Owner',
              value: branch.ownerName ?? 'Branch owner not assigned',
            ),
            _OverviewDetailRow(
              label: 'Branch',
              value: branch.branchNumber != null
                  ? 'Branch ${branch.branchNumber}'
                  : branch.name,
            ),
            _OverviewDetailRow(label: 'Address', value: branch.address ?? '-'),
            _OverviewDetailRow(
              label: 'Phone',
              value: branch.phone ?? branch.ownerPhone ?? '-',
            ),
            _OverviewDetailRow(
              label: 'Owner Since',
              value: _formatDate(branch.branchOwnerSince),
            ),
            _OverviewDetailRow(
              label: 'Coordinates',
              value: branch.lat != null && branch.lng != null
                  ? '${branch.lat}, ${branch.lng}'
                  : '-',
            ),
            if (branch.description != null && branch.description!.trim().isNotEmpty)
              _OverviewDetailRow(
                label: 'Description',
                value: branch.description!,
              ),
            _OverviewDetailRow(
              label: 'Status',
              value: branch.status ?? (branch.isActive ? 'active' : 'inactive'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_loadError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Text(
                        _loadError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track overall users, branch owners, and branches from one place.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_revenueSharingConfig != null) ...[
                    _RevenueSharingCard(
                      config: _revenueSharingConfig!,
                      onEdit: _showRevenueSharingDialog,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _AdminRevenueCard(
                    selectedMonth: _selectedMonth,
                    monthOptions: _availableMonths,
                    onMonthChanged: _changeMonth,
                    summary: _companyWalletSummary,
                    metrics: _adminRevenueMetrics,
                    error: _companyFinanceError,
                    moneyFormatter: _money,
                    monthFormatter: _formatMonthLabel,
                    dateTimeFormatter: _dateTimeLabel,
                    transactions: _companyTransactions,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _OverviewStatCard(
                        label: 'Total Users',
                        value: '${_users.length}',
                        icon: Icons.group_rounded,
                        color: const Color(0xFF1D4ED8),
                      ),
                      _OverviewStatCard(
                        label: 'Total Branches',
                        value: '${_branches.length}',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                      _OverviewStatCard(
                        label: 'Mapped Branches',
                        value: '${_mappableBranches.length}',
                        icon: Icons.place_rounded,
                        color: const Color(0xFFB45309),
                      ),
                      _OverviewStatCard(
                        label: 'Active Branches',
                        value: '$_activeBranchCount',
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF15803D),
                      ),
                      _OverviewStatCard(
                        label: 'Branch Owners',
                        value: '$_branchOwnerCount',
                        icon: Icons.business_center_rounded,
                        color: const Color(0xFFBE123C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildMapCard(height: 620),
                ],
              ),
            ),
    );
  }

  Widget _buildMapCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Branch Map',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Our Branch Partners - Chonhchoun Team',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(11.5564, 104.9282),
                  initialZoom: 8,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$mapTilerKey',
                    userAgentPackageName: 'com.chonhchoun.delivery',
                    tileDisplay: const TileDisplay.fadeIn(),
                  ),
                  MarkerLayer(
                    markers: _mappableBranches
                        .map(
                          (branch) => Marker(
                            point: LatLng(branch.lat!, branch.lng!),
                            width: 74,
                            height: 92,
                            child: GestureDetector(
                              onTap: () => _showBranchDetails(branch),
                              child: Tooltip(
                                waitDuration: const Duration(milliseconds: 150),
                                message: _buildTooltipMessage(branch),
                                child: _MapMarker(
                                  logoPath: _resolvedLogoPath(branch),
                                  defaultLogoPath: _defaultLogoPath,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _AdminRevenueCard extends StatelessWidget {
  const _AdminRevenueCard({
    required this.selectedMonth,
    required this.monthOptions,
    required this.onMonthChanged,
    required this.summary,
    required this.metrics,
    required this.error,
    required this.moneyFormatter,
    required this.monthFormatter,
    required this.dateTimeFormatter,
    required this.transactions,
  });

  final DateTime selectedMonth;
  final List<DateTime> monthOptions;
  final Future<void> Function(DateTime month) onMonthChanged;
  final CompanyWalletSummary? summary;
  final _AdminRevenueMetrics metrics;
  final String? error;
  final String Function(double amount, String currency) moneyFormatter;
  final String Function(DateTime value) monthFormatter;
  final String Function(DateTime? value) dateTimeFormatter;
  final List<CompanyWalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final currency = summary?.currency ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Revenue Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review company share, branch share, and total income by month.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<DateTime>(
                  value: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: monthOptions
                      .map(
                        (month) => DropdownMenuItem<DateTime>(
                          value: month,
                          child: Text(monthFormatter(month)),
                        ),
                      )
                      .toList(),
                  onChanged: (month) {
                    if (month != null) {
                      onMonthChanged(month);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _RulePill(
                label: 'Total Revenue',
                value: moneyFormatter(metrics.grossRevenue, currency),
                color: const Color(0xFF1D4ED8),
              ),
              _RulePill(
                label: 'Admin Income',
                value: moneyFormatter(metrics.companyIncome, currency),
                color: const Color(0xFF15803D),
              ),
              _RulePill(
                label: 'Branch Income',
                value: moneyFormatter(metrics.branchIncome, currency),
                color: const Color(0xFF7C3AED),
              ),
              _RulePill(
                label: 'Completed Deliveries',
                value: '${metrics.completedDeliveries}',
                color: const Color(0xFFB45309),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Current company wallet balance: ${moneyFormatter(summary?.availableBalance ?? 0, currency)}. This report shows the selected month only and helps compare company income against the total ticket revenue handled during that month.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Recent company revenue transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Text(
              'No company revenue transactions for the selected month.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            )
          else
            ...transactions.take(6).map(
              (transaction) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (transaction.type == 'DEBIT'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7))
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        transaction.type == 'DEBIT'
                            ? Icons.call_made_rounded
                            : Icons.call_received_rounded,
                        color: transaction.type == 'DEBIT'
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ticket: ${transaction.ticketNumber ?? '-'} • ${transaction.status}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (transaction.totalPrice != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Total revenue: ${moneyFormatter(transaction.totalPrice!, currency)} • Company share: ${transaction.revenueSharePercent ?? '-'}%',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          moneyFormatter(transaction.amount, currency),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: transaction.type == 'DEBIT'
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateTimeFormatter(transaction.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminRevenueMetrics {
  const _AdminRevenueMetrics({
    required this.grossRevenue,
    required this.companyIncome,
    required this.branchIncome,
    required this.completedDeliveries,
  });

  final double grossRevenue;
  final double companyIncome;
  final double branchIncome;
  final int completedDeliveries;
}

class _MonthRange {
  const _MonthRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

class _RevenueSharingCard extends StatelessWidget {
  final RevenueSharingConfig config;
  final Future<void> Function() onEdit;

  const _RevenueSharingCard({
    required this.config,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Sharing Rule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Admin controls the active shipment revenue-sharing version here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Update Rule'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _RulePill(
                label: 'Sender Branch',
                value: '${config.senderBranchPercent}%',
                color: const Color(0xFF1D4ED8),
              ),
              _RulePill(
                label: 'Receiver Branch',
                value: '${config.receiverBranchPercent}%',
                color: const Color(0xFF7C3AED),
              ),
              _RulePill(
                label: 'Company/Admin',
                value: '${config.companyPercent}%',
                color: const Color(0xFF15803D),
              ),
              _RulePill(
                label: 'Version',
                value: 'v${config.version}',
                color: const Color(0xFFB45309),
              ),
            ],
          ),
          if (config.note != null && config.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Note: ${config.note!}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RulePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RulePill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 215,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String logoPath;
  final String defaultLogoPath;

  const _MapMarker({
    required this.logoPath,
    required this.defaultLogoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: _BranchLogoImage(
              logoPath: logoPath,
              defaultLogoPath: defaultLogoPath,
            ),
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: Color(0xFF1E3A5F),
          size: 28,
        ),
      ],
    );
  }
}

class _PopupLogo extends StatelessWidget {
  final String logoPath;
  final String defaultLogoPath;
  final double size;

  const _PopupLogo({
    required this.logoPath,
    required this.defaultLogoPath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE0F2FE),
      ),
      clipBehavior: Clip.antiAlias,
      child: _BranchLogoImage(
        logoPath: logoPath,
        defaultLogoPath: defaultLogoPath,
      ),
    );
  }
}

class _BranchLogoImage extends StatelessWidget {
  final String logoPath;
  final String defaultLogoPath;

  const _BranchLogoImage({
    required this.logoPath,
    required this.defaultLogoPath,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackImage = Image.asset(defaultLogoPath, fit: BoxFit.cover);
    final isNetworkImage =
        logoPath.startsWith('http://') || logoPath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        logoPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallbackImage,
      );
    }

    return Image.asset(
      logoPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallbackImage,
    );
  }
}

class _OverviewDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
