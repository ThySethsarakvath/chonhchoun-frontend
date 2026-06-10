import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../global/base_url.dart';
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

  final _userService = AdminUserService();
  final _branchService = BranchService();

  List<AdminUser> _users = [];
  List<Branch> _branches = [];
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
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<AdminUser>;
        _branches = results[1] as List<Branch>;
      });
    } catch (_) {
    } finally {
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
