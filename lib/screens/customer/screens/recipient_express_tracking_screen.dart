import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/data/map_data.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/utils/route_motion.dart';
import '../../../shared/widgets/app_shell_widgets.dart';

class RecipientExpressTrackingScreen extends StatefulWidget {
  const RecipientExpressTrackingScreen({required this.token, super.key});

  final String token;

  @override
  State<RecipientExpressTrackingScreen> createState() =>
      _RecipientExpressTrackingScreenState();
}

class _RecipientExpressTrackingScreenState
    extends State<RecipientExpressTrackingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _frameController;
  Map<String, dynamic>? _delivery;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
    _frameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onAnimationFrame)
          ..repeat();
  }

  void _onAnimationFrame() {
    if (_delivery?['status']?.toString() == 'IN_TRANSIT') {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/express-deliveries/recipient/${widget.token}'),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _delivery = body;
          _error = null;
          _loading = false;
        });
        return;
      }
      throw Exception('មិនអាចផ្ទុកការតាមដានបានទេ។');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'មិនអាចផ្ទុកការតាមដានបានទេ។ សូមព្យាយាមម្ដងទៀត។';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ការដឹកជញ្ជូនមកដល់',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'ការតាមដានផ្ទាល់សម្រាប់អ្នកទទួល',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final delivery = _delivery!;
    final trackingEnabled = delivery['trackingEnabled'] == true;
    final status = delivery['status']?.toString() ?? 'PENDING';
    final package = delivery['package'] as Map? ?? const {};
    final dropoff = delivery['dropoff'] as Map? ?? const {};
    final driver = delivery['driver'] as Map?;
    final dropoffToken = delivery['dropoffQrToken']?.toString();
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.52).clamp(
      360.0,
      540.0,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.section,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.customerContentMaxWidth,
              ),
              child: Column(
                children: [
                  AppSurfaceCard(
                    child: Semantics(
                      liveRegion: true,
                      label: 'ស្ថានភាពការដឹកជញ្ជូន៖ ${_statusLabel(status)}',
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: trackingEnabled
                                  ? AppColors.softBlue
                                  : AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              trackingEnabled
                                  ? Icons.delivery_dining_rounded
                                  : Icons.lock_clock_rounded,
                              color: trackingEnabled
                                  ? AppColors.blue
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusLabel(status),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  trackingEnabled
                                      ? 'ផ្លូវធ្វើដំណើរកំពុងធ្វើបច្ចុប្បន្នភាពដោយស្វ័យប្រវត្តិ។'
                                      : 'ការតាមដាននឹងបើកបន្ទាប់ពីអ្នកផ្ញើបញ្ជាក់ការប្រគល់កញ្ចប់។',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (trackingEnabled) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: mapHeight,
                      child: _RecipientRouteMap(delivery: delivery),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.blue,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'កញ្ចប់កំពុងមកដល់',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        _detail(
                          'ទំនិញ',
                          package['name']?.toString() ?? 'កញ្ចប់ទំនិញ',
                        ),
                        _detail(
                          'ចំនួន',
                          package['quantity']?.toString() ?? '1',
                        ),
                        _detail(
                          'ប្រគល់ទៅ',
                          dropoff['address']?.toString() ?? 'ទីតាំងគោលដៅ',
                        ),
                        if (driver != null)
                          _detail(
                            'អ្នកបើកបរ',
                            driver['name']?.toString() ?? 'បានកំណត់',
                          ),
                      ],
                    ),
                  ),
                  if (dropoffToken != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppSurfaceCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppColors.blue,
                            size: 32,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'ការបញ្ជាក់ការប្រគល់ទំនិញ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'ពិនិត្យកញ្ចប់ និងចំនួនឱ្យត្រឹមត្រូវ រួចឱ្យអ្នកបើកបរស្កេនកូដនេះ។',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: QrImageView(
                              data: 'chonhchoun:dropoff:$dropoffToken',
                              size: 210,
                            ),
                          ),
                        ],
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'IN_TRANSIT':
        return 'កញ្ចប់របស់អ្នកកំពុងធ្វើដំណើរមក';
      case 'ARRIVED_AT_DROPOFF':
        return 'អ្នកបើកបរបានមកដល់';
      case 'DELIVERED':
        return 'ការដឹកជញ្ជូនបានបញ្ចប់';
      default:
        return 'កំពុងរង់ចាំអ្នកផ្ញើប្រគល់កញ្ចប់';
    }
  }
}

class _RecipientRouteMap extends StatefulWidget {
  const _RecipientRouteMap({required this.delivery});

  final Map<String, dynamic> delivery;

  @override
  State<_RecipientRouteMap> createState() => _RecipientRouteMapState();
}

class _RecipientRouteMapState extends State<_RecipientRouteMap> {
  late List<LatLng> _route;
  final SmoothRouteProgress _progressSmoother = SmoothRouteProgress();

  @override
  void initState() {
    super.initState();
    _route = _points(widget.delivery['routePoints']);
  }

  @override
  void didUpdateWidget(_RecipientRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.delivery['routePoints'],
      widget.delivery['routePoints'],
    )) {
      _route = _points(widget.delivery['routePoints']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final route = _route;
    final dropoff = _point(delivery['dropoff']);
    final progress = _progress();
    final driverMotion = sampleRouteMotion(route, progress);
    final driverPoint = driverMotion?.position;
    final center = route.isNotEmpty
        ? route[route.length ~/ 2]
        : dropoff ?? const LatLng(11.5564, 104.9282);
    final vehicleType = delivery['vehicleType']?.toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all | InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.urlTemplate,
                  userAgentPackageName: MapConfig.userAgent,
                ),
                if (route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route,
                        strokeWidth: 5,
                        color: AppColors.blue,
                        borderStrokeWidth: 3,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (dropoff != null)
                      Marker(
                        point: dropoff,
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: AppShadows.card,
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    if (driverPoint != null)
                      Marker(
                        point: driverPoint,
                        width: 54,
                        height: 70,
                        child: Transform.rotate(
                          angle: driverMotion?.bearingRadians ?? 0,
                          child: Image.asset(
                            vehicleType == 'RICKSHAW'
                                ? 'assets/images/rickshaw_topview.png'
                                : 'assets/images/motorbike_topview.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'ផ្លូវធ្វើដំណើរផ្ទាល់',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      'អូស ឬពង្រីកបង្រួមផែនទី',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _progress() {
    final stored =
        (widget.delivery['simulationProgress'] as num?)?.toDouble() ?? 0;
    final duration =
        (widget.delivery['simulationDurationSeconds'] as num?)?.toInt() ?? 30;
    final status = widget.delivery['status']?.toString() ?? 'PENDING';
    return _progressSmoother.update(
      phaseKey: status,
      serverProgress: stored,
      durationSeconds: duration,
      completed: const {'ARRIVED_AT_DROPOFF', 'DELIVERED'}.contains(status),
    );
  }

  static List<LatLng> _points(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(_point).whereType<LatLng>().toList();
  }

  static LatLng? _point(dynamic raw) {
    if (raw is! Map) return null;
    final latitude = raw['latitude'] as num?;
    final longitude = raw['longitude'] as num?;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ព្យាយាមម្ដងទៀត'),
            ),
          ],
        ),
      ),
    );
  }
}
