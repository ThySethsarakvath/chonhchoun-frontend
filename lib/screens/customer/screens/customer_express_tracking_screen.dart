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
import 'customer_order_detail_screen.dart';

class CustomerExpressTrackingScreen extends StatefulWidget {
  const CustomerExpressTrackingScreen({super.key, required this.packageId});

  final String packageId;

  @override
  State<CustomerExpressTrackingScreen> createState() =>
      _CustomerExpressTrackingScreenState();
}

class _CustomerExpressTrackingScreenState
    extends State<CustomerExpressTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _pollTimer;
  Timer? _animationTimer;
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
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted &&
          (_order?.status == OrderStatus.accepted ||
              _order?.status == OrderStatus.inTransit)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
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
        throw Exception('Unable to refresh delivery tracking.');
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
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: QrImageView(
            data: 'chonhchoun:pickup:$token',
            version: QrVersions.auto,
            size: 250,
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
                  _error ?? 'Delivery tracking is unavailable.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _sync, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final routePoints = order.activeRoutePoints;
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
                        color: AppColors.blue,
                        strokeWidth: 5,
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
                        point: order.simulatedDriverLocation!,
                        width: 62,
                        height: 62,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            order.vehicleType == VehicleType.tuktuk
                                ? 'assets/images/rickshaw_topview.png'
                                : 'assets/images/motorbike_topview.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Material(
                  color: Colors.white,
                  elevation: 7,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                order.statusText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              if (order.driverName != null)
                                Text(
                                  '${order.driverName} • ${order.vehicleText}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fit route',
                          onPressed: _fitRoute,
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                elevation: 9,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.itemName} • ${order.quantity} item${order.quantity == 1 ? '' : 's'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${order.pickupAddress} → ${order.dropoffAddress}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerOrderDetailScreen(
                                packageId: widget.packageId,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
                        child: const Text('Details'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (order.status == OrderStatus.arrivedAtPickup)
            Positioned(
              left: 28,
              right: 28,
              bottom: 142,
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _showPickupQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Show pickup confirmation QR'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
