import 'package:flutter/material.dart';

import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/services/user_service.dart';
import '../../../features/auth/tokens/token_storage.dart';
import '../models/driver_earnings.dart';
import '../models/driver_package.dart';
import '../services/driver_dashboard_service.dart';
import '../widgets/driver_button_widgets.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_delivery_card.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverDeliveriesTab extends StatefulWidget {
  const DriverDeliveriesTab({
    super.key,
    required this.onOpenEarnings,
  });

  final VoidCallback onOpenEarnings;

  @override
  State<DriverDeliveriesTab> createState() => _DriverDeliveriesTabState();
}

class _DriverDeliveriesTabState extends State<DriverDeliveriesTab> {
  final UserService _userService = UserService();
  final DriverDashboardService _dashboard = DriverDashboardService();

  UserProfile? _profile;
  DriverEarningsSummary? _earnings;
  List<DriverPackage> _packages = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      _userService.getMe(accessToken: token).then<Object?>((v) => v).catchError((_) => null),
      _dashboard.fetchEarnings(token).then<Object?>((v) => v).catchError((_) => null),
      _dashboard.fetchAssignedPackages(token).then<Object?>((v) => v).catchError((_) => null),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as UserProfile?;
      _earnings = results[1] as DriverEarningsSummary?;
      final packages = results[2];
      if (packages != null) _packages = packages as List<DriverPackage>;
      _loading = false;
    });
  }

  String get _name {
    final n = _profile?.name.trim();
    return (n != null && n.isNotEmpty) ? n : 'Driver';
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _earnings;
    final balanceLabel =
        earnings != null ? earnings.availableBalance.toStringAsFixed(2) : '—';
    final active = _packages.where((p) => p.isActive).toList();
    final past = _packages.where((p) => !p.isActive).toList();

    return RefreshIndicator(
      color: DriverColors.blue,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DriverHeroSection(
            subtitle: 'Weekly Overview',
            name: _name,
            content: DriverBalanceCard(amount: balanceLabel),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  DriverSurfaceCard(
                    child: Column(
                      children: [
                        const Text(
                          'This week',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DriverStatLine(
                          label: 'Earned',
                          value: earnings != null
                              ? '\$${earnings.weekly.fold<double>(0, (s, d) => s + d.amount).toStringAsFixed(2)}'
                              : '—',
                        ),
                        const SizedBox(height: 16),
                        DriverStatLine(
                          label: 'Online time',
                          value: earnings?.onlineLabel ?? '—',
                        ),
                        const SizedBox(height: 16),
                        DriverStatLine(
                          label: 'Completed deliveries',
                          value: earnings != null
                              ? '${earnings.completedDeliveries}'
                              : '—',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: DriverPrimaryButton(
                            label: 'See earnings',
                            onPressed: widget.onOpenEarnings,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Active deliveries (${active.length})',
                      style: const TextStyle(
                        color: DriverColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: DriverColors.blue),
                      ),
                    )
                  else if (active.isEmpty)
                    const _EmptyDeliveries()
                  else
                    ...active.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverDeliveryCard(package: p),
                      ),
                    ),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Completed (${past.length})',
                        style: const TextStyle(
                          color: DriverColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...past.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverDeliveryCard(package: p),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDeliveries extends StatelessWidget {
  const _EmptyDeliveries();

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: DriverColors.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.inbox_rounded, color: DriverColors.blue),
          ),
          const SizedBox(height: 14),
          const Text(
            'No active deliveries',
            style: TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'New deliveries assigned to you appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted),
          ),
        ],
      ),
    );
  }
}
