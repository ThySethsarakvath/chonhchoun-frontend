import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/admin_activity_model.dart';
import '../models/admin_user_model.dart';
import '../models/branch_model.dart';
import '../services/admin_user_service.dart';
import '../services/branch_service.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  static const String _defaultLogoPath = 'assets/images/bluelogo.png';
  static const String _mapTilerKey = 'k0zSDACY9KkW3e9NetrQ';

  final _userService = AdminUserService();
  final _branchService = BranchService();

  List<AdminUser> _users = [];
  List<Branch> _branches = [];
  List<AdminActivity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _userService.getUsers(),
        _branchService.getAllBranches(),
        _userService.getActivityHistory(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<AdminUser>;
          _branches = results[1] as List<Branch>;
          _activities = results[2] as List<AdminActivity>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

  int get _agentCount => _users
      .where((user) => user.role == 'driver' || user.role == 'agency')
      .length;

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

  String _formatDateTime(DateTime? value) {
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

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day.toString().padLeft(2, '0')} ${monthNames[value.month - 1]} ${value.year}, $hour:$minute';
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
                  logoPath: _defaultLogoPath,
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
              label: 'Branch',
              value: branch.branchNumber != null
                  ? 'Branch ${branch.branchNumber}'
                  : branch.name,
            ),
            _OverviewDetailRow(label: 'Address', value: branch.address ?? '-'),
            _OverviewDetailRow(label: 'Phone', value: branch.phone ?? '-'),
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
                    'Track overall users, agents, and branches from one place.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
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
                        label: 'Total Agents',
                        value: '$_agentCount',
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFF0F766E),
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
                  const SizedBox(height: 24),
                  _buildActivityHistoryCard(),
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
                        'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$_mapTilerKey',
                    userAgentPackageName: 'com.chonhchoun.delivery',
                    tileDisplay: const TileDisplay.fadeIn(),
                  ),
                  MarkerLayer(
                    markers: _mappableBranches
                        .map(
                          (branch) => Marker(
                            point: LatLng(branch.lat!, branch.lng!),
                            width: 58,
                            height: 72,
                            child: GestureDetector(
                              onTap: () => _showBranchDetails(branch),
                              child: Tooltip(
                                waitDuration: const Duration(milliseconds: 150),
                                message:
                                    '${branch.name}\n${branch.address ?? '-'}',
                                child: _MapMarker(
                                  logoPath: _defaultLogoPath,
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

  Widget _buildActivityHistoryCard() {
    return Container(
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
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Activity History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track who upgraded or downgraded users, when branches were created, and when branches were closed.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No activity has been recorded yet.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ..._activities.take(12).map(_buildActivityTile),
        ],
      ),
    );
  }

  Widget _buildActivityTile(AdminActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.details ?? _buildActivityFallback(activity),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(activity.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildActivityFallback(AdminActivity activity) {
    switch (activity.action) {
      case 'branch_owner_upgraded':
        return '${activity.actorName} upgraded ${activity.targetUserName ?? 'a user'}.';
      case 'branch_owner_downgraded':
        return '${activity.actorName} downgraded ${activity.targetUserName ?? 'a user'}.';
      case 'branch_created':
        return '${activity.branchName ?? 'A branch'} was created.';
      case 'branch_closed':
        return '${activity.branchName ?? 'A branch'} was closed.';
      default:
        return activity.action;
    }
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
    final hasNetworkLogo =
        logoPath.startsWith('http://') || logoPath.startsWith('https://');

    final imageWidget = hasNetworkLogo
        ? Image.network(
            logoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              defaultLogoPath,
              fit: BoxFit.cover,
            ),
          )
        : Image.asset(
            logoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              defaultLogoPath,
              fit: BoxFit.cover,
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(child: imageWidget),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: Color(0xFF1E3A5F),
          size: 22,
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
    final image = logoPath.startsWith('http://') || logoPath.startsWith('https://')
        ? Image.network(
            logoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              defaultLogoPath,
              fit: BoxFit.cover,
            ),
          )
        : Image.asset(
            logoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              defaultLogoPath,
              fit: BoxFit.cover,
            ),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE0F2FE),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
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
