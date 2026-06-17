import 'package:flutter/material.dart';

import '../../../features/auth/tokens/token_storage.dart';
import '../models/driver_route.dart';
import '../services/driver_dashboard_service.dart';
import '../widgets/driver_colors.dart';
import '../widgets/driver_route_map.dart';
import '../widgets/driver_shell_widgets.dart';

class DriverRouteTab extends StatefulWidget {
  const DriverRouteTab({super.key});

  @override
  State<DriverRouteTab> createState() => _DriverRouteTabState();
}

class _DriverRouteTabState extends State<DriverRouteTab> {
  final DriverDashboardService _service = DriverDashboardService();

  DriverRoutePlan? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Please sign in again to load your route.';
          });
        }
        return;
      }
      final plan = await _service.fetchRoute(token);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your route. Pull to retry.';
        });
      }
    }
  }

  String _etaLabel(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes <= 0) return 'now';
    if (minutes < 60) return 'in ~$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? 'in ~${hours}h' : 'in ~${hours}h ${rest}m';
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

    return RefreshIndicator(
      color: DriverColors.blue,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DriverHeroSection(
            subtitle: 'Auto-mapped route',
            name: "Today's route",
            content: _RouteSummaryCard(
              plan: plan,
              loading: _loading,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _buildBody(plan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DriverRoutePlan? plan) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(color: DriverColors.blue),
        ),
      );
    }

    if (plan == null) {
      return _RouteEmptyState(message: _error);
    }

    return Column(
      children: [
        DriverSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Optimised path',
                      style: TextStyle(
                        color: DriverColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (plan.isSample)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DriverColors.muted.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Sample',
                        style: TextStyle(
                          color: DriverColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  child: DriverRouteMap(plan: plan),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _RouteMetric(
                      icon: Icons.schedule_rounded,
                      value: plan.durationLabel,
                      label: 'Duration',
                    ),
                  ),
                  Expanded(
                    child: _RouteMetric(
                      icon: Icons.place_rounded,
                      value: '${plan.totalStops}',
                      label: 'Stops',
                    ),
                  ),
                  Expanded(
                    child: _RouteMetric(
                      icon: Icons.inventory_2_rounded,
                      value: '${plan.totalPackages}',
                      label: 'Packages',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DriverSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stops',
                style: TextStyle(
                  color: DriverColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _RouteTimeline(
                plan: plan,
                etaLabel: _etaLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.plan, required this.loading});

  final DriverRoutePlan? plan;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final duration = plan?.durationLabel ?? '—';
    final stops = plan?.totalStops ?? 0;
    final packages = plan?.totalPackages ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Estimated time',
                      style: TextStyle(color: DriverColors.text, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (loading)
                      const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DriverColors.blue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: const TextStyle(
                    color: DriverColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$stops stops · $packages packages',
                  style: const TextStyle(
                    color: DriverColors.text,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.route_rounded,
                color: DriverColors.blueDark, size: 28),
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DriverColors.blue, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: DriverColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: DriverColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({
    required this.plan,
    required this.etaLabel,
  });

  final DriverRoutePlan plan;
  final String Function(int) etaLabel;

  @override
  Widget build(BuildContext context) {
    final source = plan.source;
    return Column(
      children: [
        if (source != null)
          _TimelineRow(
            isFirst: true,
            isLast: plan.stops.isEmpty,
            badge: const Icon(Icons.warehouse_rounded,
                color: Colors.white, size: 16),
            badgeColor: DriverColors.blueDark,
            title: source.branchName,
            subtitle: 'Pickup origin · start here',
            trailing: null,
          ),
        for (var i = 0; i < plan.stops.length; i++)
          _TimelineRow(
            isFirst: source == null && i == 0,
            isLast: i == plan.stops.length - 1,
            badge: Text(
              '${plan.stops[i].order}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            badgeColor: DriverColors.success,
            title: plan.stops[i].branchName,
            subtitle:
                '${plan.stops[i].packageCount} packages · arrives ${etaLabel(plan.stops[i].etaSeconds)}',
            trailing: null,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final bool isFirst;
  final bool isLast;
  final Widget badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 8,
                color: isFirst ? Colors.transparent : DriverColors.line,
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: badge),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : DriverColors.line,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: DriverColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DriverColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _RouteEmptyState extends StatelessWidget {
  const _RouteEmptyState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: DriverColors.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.map_outlined,
                color: DriverColors.blue, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'No route assigned yet',
            style: TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ??
                'When dispatch auto-maps a delivery to you, the optimised route appears here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: DriverColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
