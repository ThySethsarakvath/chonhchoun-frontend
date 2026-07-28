import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../features/auth/tokens/token_storage.dart';
import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/data/map_data.dart';
import '../../../shared/models/order.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/utils/route_motion.dart';
import '../customer_khmer.dart';
import 'customer_order_detail_screen.dart';

class CustomerExpressTrackingScreen extends StatefulWidget {
  const CustomerExpressTrackingScreen({super.key, required this.packageId});

  final String packageId;

  @override
  State<CustomerExpressTrackingScreen> createState() =>
      _CustomerExpressTrackingScreenState();
}

class _CustomerExpressTrackingScreenState
    extends State<CustomerExpressTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final SmoothRouteProgress _progressSmoother = SmoothRouteProgress();
  Timer? _pollTimer;
  late final AnimationController _frameController;
  CustomerOrder? _order;
  bool _mapReady = false;
  bool _loading = true;
  bool _requestInFlight = false;
  String? _error;
  OrderStatus? _lastFittedStatus;

  @override
  void initState() {
    super.initState();
    _sync();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _sync(silent: true),
    );
    _frameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onAnimationFrame)
          ..repeat();
  }

  void _onAnimationFrame() {
    if (_order?.status == OrderStatus.accepted ||
        _order?.status == OrderStatus.inTransit) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _frameController.dispose();
    super.dispose();
  }

  Future<void> _sync({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/packages/${widget.packageId}/simulation/sync'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('មិនអាចធ្វើបច្ចុប្បន្នភាពការតាមដានបានទេ។');
      }
      final order = CustomerOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      if (!mounted) return;
      final shouldFit = _lastFittedStatus != order.status;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
        _lastFittedStatus = order.status;
      });
      if (shouldFit) _fitRoute();
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = 'មិនអាចធ្វើបច្ចុប្បន្នភាពការតាមដានបានទេ។ សូមព្យាយាមម្ដងទៀត។';
      });
    } finally {
      _requestInFlight = false;
    }
  }

  void _fitRoute() {
    final order = _order;
    if (!_mapReady || order == null) return;
    final points = <LatLng>[
      ...order.activeRoutePoints,
      order.pickup,
      order.dropoff,
      if (order.simulatedDriverLocation != null) order.simulatedDriverLocation!,
    ];
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(42, 150, 42, 190),
        ),
      );
    });
  }

  void _showPickupQr() {
    final token = _order?.pickupQrToken;
    if (token == null || token.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'បិទ',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.blue,
                    size: 34,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ការបញ្ជាក់ទទួលកញ្ចប់',
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'អនុញ្ញាតឱ្យអ្នកបើកបរស្កេនកូដនេះ មុនចាប់ផ្ដើមការដឹកជញ្ជូន។',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: QrImageView(
                      data: 'chonhchoun:pickup:$token',
                      version: QrVersions.auto,
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'ការបញ្ជាក់សុវត្ថិភាពប្រើបានតែម្ដង',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _order == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_order == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: AppColors.danger,
                  size: 46,
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'មិនអាចប្រើការតាមដានការដឹកជញ្ជូនបានទេ។',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _sync,
                  child: const Text('ព្យាយាមម្ដងទៀត'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final routePoints = order.activeRoutePoints;
    final driverMotion = sampleRouteMotion(
      routePoints,
      _progressSmoother.update(
        phaseKey: order.status.name,
        serverProgress: order.simulationProgress,
        durationSeconds: order.simulationDurationSeconds,
        completed: const {
          OrderStatus.arrivedAtPickup,
          OrderStatus.arrivedAtDropoff,
          OrderStatus.delivered,
        }.contains(order.status),
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: order.pickup,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onMapReady: () {
                  _mapReady = true;
                  _fitRoute();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.urlTemplate,
                  userAgentPackageName: MapConfig.userAgent,
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.white.withValues(alpha: 0.9),
                        strokeWidth: 9,
                      ),
                      Polyline(
                        points: routePoints,
                        color: AppColors.blue,
                        strokeWidth: 5.5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: order.pickup,
                      width: 44,
                      height: 44,
                      child: const _MapPin(
                        color: AppColors.blue,
                        icon: Icons.inventory_2,
                      ),
                    ),
                    Marker(
                      point: order.dropoff,
                      width: 44,
                      height: 44,
                      child: const _MapPin(
                        color: AppColors.danger,
                        icon: Icons.flag,
                      ),
                    ),
                    if (order.simulatedDriverLocation != null)
                      Marker(
                        point:
                            driverMotion?.position ??
                            order.simulatedDriverLocation!,
                        width: 54,
                        height: 70,
                        child: Transform.rotate(
                          angle: driverMotion?.bearingRadians ?? 0,
                          child: Image.asset(
                            order.vehicleType == VehicleType.tuktuk
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
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.customerContentMaxWidth,
                  ),
                  child: _TrackingHeader(
                    order: order,
                    onBack: () => Navigator.maybePop(context),
                    onFitRoute: _fitRoute,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.customerContentMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.standard,
                      switchInCurve: AppMotion.standardCurve,
                      child: order.status == OrderStatus.arrivedAtPickup
                          ? Padding(
                              key: const ValueKey('pickup-qr-action'),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: FilledButton.icon(
                                onPressed: _showPickupQr,
                                icon: const Icon(Icons.qr_code_2_rounded),
                                label: const Text(
                                  'បង្ហាញ QR បញ្ជាក់ទទួលកញ្ចប់',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: AppColors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    _DeliverySummaryCard(
                      order: order,
                      onDetails: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerOrderDetailScreen(
                              packageId: widget.packageId,
                            ),
                          ),
                        );
                      },
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
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({
    required this.order,
    required this.onBack,
    required this.onFitRoute,
  });

  final CustomerOrder order;
  final VoidCallback onBack;
  final VoidCallback onFitRoute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.floating,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'ត្រឡប់ក្រោយ',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label:
                    'ស្ថានភាពការដឹកជញ្ជូន៖ ${customerOrderStatusKhmer(order)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.driverName == null
                          ? 'ការតាមដានការដឹកជញ្ជូនផ្ទាល់'
                          : '${order.driverName} • ${customerVehicleKhmer(order.vehicleType)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'បង្ហាញផ្លូវទាំងមូល',
              onPressed: onFitRoute,
              icon: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySummaryCard extends StatelessWidget {
  const _DeliverySummaryCard({required this.order, required this.onDetails});

  final CustomerOrder order;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.itemName} • ${order.quantity} មុខទំនិញ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${order.pickupAddress} → ${order.dropoffAddress}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'មើលព័ត៌មានលម្អិតការដឹកជញ្ជូន',
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.softBlue,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
