import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/branch_model.dart';
import '../services/branch_service.dart';

class AdminAgentScreen extends StatefulWidget {
  const AdminAgentScreen({super.key});

  static const String mapTilerKey = 'k0zSDACY9KkW3e9NetrQ';

  @override
  State<AdminAgentScreen> createState() => _AdminAgentScreenState();
}

class _AdminAgentScreenState extends State<AdminAgentScreen> {
  final _service = BranchService();

  List<Branch> _branches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _service.getMapBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
                _BranchMarker(branch: branch, size: 52),
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
                      const Text(
                        'Branch Partner',
                        style: TextStyle(
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
            _DetailRow(label: 'Address', value: branch.address ?? '-'),
            _DetailRow(label: 'Phone', value: branch.phone ?? '-'),
            _DetailRow(label: 'Status', value: branch.status ?? 'active'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Branch Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBranches,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(11.5564, 104.9282),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=${AdminAgentScreen.mapTilerKey}',
                  userAgentPackageName: 'com.chonhchoun.delivery',
                  tileDisplay: const TileDisplay.fadeIn(),
                ),
                MarkerLayer(
                  markers: _branches
                      .where((branch) => branch.lat != null && branch.lng != null)
                      .map(
                        (branch) => Marker(
                          point: LatLng(branch.lat!, branch.lng!),
                          width: 56,
                          height: 56,
                          child: GestureDetector(
                            onTap: () => _showBranchDetails(branch),
                            child: Tooltip(
                              message:
                                  '${branch.name}\n${branch.address ?? '-'}\n${branch.phone ?? '-'}',
                              child: _BranchMarker(branch: branch),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class _BranchMarker extends StatelessWidget {
  final Branch branch;
  final double size;

  const _BranchMarker({
    required this.branch,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = branch.logoUrl;
    final hasNetworkLogo =
        logoUrl != null &&
        logoUrl.isNotEmpty &&
        (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'));
    final hasAssetLogo =
        logoUrl != null && logoUrl.isNotEmpty && logoUrl.startsWith('assets/');

    if (!hasNetworkLogo && !hasAssetLogo) {
      return const Icon(
        Icons.location_on,
        size: 42,
        color: Colors.blue,
      );
    }

    final imageWidget = hasNetworkLogo
        ? Image.network(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.location_on,
              size: 42,
              color: Colors.blue,
            ),
          )
        : Image.asset(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.location_on,
              size: 42,
              color: Colors.blue,
            ),
          );

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
