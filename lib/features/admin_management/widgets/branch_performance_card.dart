import 'package:flutter/material.dart';

import '../models/branch_model.dart';

class BranchPerformanceCard extends StatelessWidget {
  static const String _defaultLogoPath = 'assets/images/branch_partner_logo.png';

  final Branch branch;

  const BranchPerformanceCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final branchTitle = branch.branchNumber != null
        ? 'Branch ${branch.branchNumber}'
        : branch.name;
    final statusLabel =
        branch.status ?? (branch.isActive ? 'active' : 'inactive');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BranchLogo(logoUrl: branch.logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              _StatusChip(label: statusLabel),
            ],
          ),
          const SizedBox(height: 18),
          _DetailLine(
            label: 'Address',
            value: branch.address ?? 'No address available',
          ),
          const SizedBox(height: 10),
          _DetailLine(
            label: 'Phone',
            value: branch.phone ?? '-',
          ),
          const SizedBox(height: 10),
          _DetailLine(
            label: 'Map',
            value: branch.lat != null && branch.lng != null
                ? '${branch.lat}, ${branch.lng}'
                : 'No coordinates',
          ),
        ],
      ),
    );
  }
}

class _BranchLogo extends StatelessWidget {
  final String? logoUrl;

  const _BranchLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final resolved = logoUrl == null ||
            logoUrl!.isEmpty ||
            logoUrl == 'assets/images/logo.png'
        ? BranchPerformanceCard._defaultLogoPath
        : logoUrl!;
    final isNetwork =
        resolved.startsWith('http://') || resolved.startsWith('https://');

    final image = isNetwork
        ? Image.network(
            resolved,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              BranchPerformanceCard._defaultLogoPath,
              fit: BoxFit.cover,
            ),
          )
        : Image.asset(
            resolved,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              BranchPerformanceCard._defaultLogoPath,
              fit: BoxFit.cover,
            ),
          );

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE0F2FE),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = label == 'active';
    final color = isActive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
