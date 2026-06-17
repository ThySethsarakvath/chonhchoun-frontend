import 'package:flutter/material.dart';

import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/services/user_service.dart';
import '../../../features/auth/tokens/token_storage.dart';
import '../models/driver_package.dart';
import '../services/driver_dashboard_service.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_delivery_card.dart';
import '../widgets/driver_request_widgets.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverHomeTab extends StatefulWidget {
  const DriverHomeTab({
    super.key,
    required this.onOpenEarnings,
    required this.onOpenRoute,
  });

  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenRoute;

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  final UserService _userService = UserService();
  final DriverDashboardService _dashboard = DriverDashboardService();

  UserProfile? _profile;
  double? _balance;
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
      final earnings = results[1];
      if (earnings != null) _balance = (earnings as dynamic).availableBalance as double;
      final packages = results[2];
      if (packages != null) _packages = packages as List<DriverPackage>;
      _loading = false;
    });
  }

  String get _name {
    final n = _profile?.name.trim();
    return (n != null && n.isNotEmpty) ? n : 'Driver';
  }

  String get _balanceLabel =>
      _balance != null ? _balance!.toStringAsFixed(2) : '—';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DriverColors.blue,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DriverHeroSection(
            subtitle: 'Welcome Back',
            name: _name,
            content: _TappableBalance(
              onTap: widget.onOpenEarnings,
              child: DriverBalanceCard(amount: _balanceLabel),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  _RouteCtaCard(onTap: widget.onOpenRoute),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your deliveries',
                          style: TextStyle(
                            color: DriverColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_packages.isNotEmpty)
                        Text(
                          '${_packages.where((p) => p.isActive).length} active',
                          style: const TextStyle(
                            color: DriverColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DriverColors.blue,
                        ),
                      ),
                    )
                  else if (_packages.isEmpty)
                    const _NoDeliveries()
                  else
                    ..._packages.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverDeliveryCard(package: p),
                      ),
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

class _NoDeliveries extends StatelessWidget {
  const _NoDeliveries();

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
            child: const Icon(Icons.local_shipping_outlined,
                color: DriverColors.blue),
          ),
          const SizedBox(height: 14),
          const Text(
            'No deliveries assigned',
            style: TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assigned deliveries will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RouteCtaCard extends StatelessWidget {
  const _RouteCtaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: DriverSurfaceCard(
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [DriverColors.blue, DriverColors.blueDark],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.route_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's route",
                    style: TextStyle(
                      color: DriverColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'See your auto-mapped stops and ETAs',
                    style: TextStyle(color: DriverColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DriverColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TappableBalance extends StatelessWidget {
  const _TappableBalance({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 18,
            right: 18,
            child: Row(
              children: [
                Text(
                  'View earnings',
                  style: TextStyle(
                    color: DriverColors.blue.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: DriverColors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
