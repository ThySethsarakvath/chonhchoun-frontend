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
import '../../../shared/widgets/app_shell_widgets.dart';

class RecipientExpressTrackingScreen extends StatefulWidget {
  const RecipientExpressTrackingScreen({required this.token, super.key});

  final String token;

  @override
  State<RecipientExpressTrackingScreen> createState() =>
      _RecipientExpressTrackingScreenState();
}

class _RecipientExpressTrackingScreenState
    extends State<RecipientExpressTrackingScreen> {
  Timer? _timer;
  Timer? _animationTimer;
  Map<String, dynamic>? _delivery;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      final status = _delivery?['status']?.toString();
      if (mounted && status == 'IN_TRANSIT') setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationTimer?.cancel();
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
      throw Exception(
        body is Map<String, dynamic>
            ? body['message']?.toString()
            : 'Unable to load tracking.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Incoming Express Delivery',
          style: TextStyle(fontWeight: FontWeight.w700),
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    trackingEnabled
                        ? Icons.delivery_dining_rounded
                        : Icons.lock_clock_rounded,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 3),
                      Text(
                        trackingEnabled
                            ? 'Live simulated tracking is available.'
                            : 'Tracking unlocks after sender handoff verification.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (trackingEnabled) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 420,
              child: _RecipientRouteMap(delivery: delivery),
            ),
          ],
          const SizedBox(height: 16),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Package arriving',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const Divider(height: 24),
                _detail('Item', package['name']?.toString() ?? 'Package'),
                _detail('Quantity', package['quantity']?.toString() ?? '1'),
                _detail(
                  'Deliver to',
                  dropoff['address']?.toString() ?? 'Destination',
                ),
                if (driver != null)
                  _detail('Driver', driver['name']?.toString() ?? 'Assigned'),
              ],
            ),
          ),
          if (dropoffToken != null) ...[
            const SizedBox(height: 16),
            AppSurfaceCard(
              child: Column(
                children: [
                  const Text(
                    'Delivery Confirmation QR',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check the package and quantity, then let the driver scan this code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: 'chonhchoun:dropoff:$dropoffToken',
                    size: 220,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
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
        return 'Your package is on the way';
      case 'ARRIVED_AT_DROPOFF':
        return 'Driver has arrived';
      case 'DELIVERED':
        return 'Delivery completed';
      default:
        return 'Waiting for sender handoff';
    }
  }
}

class _RecipientRouteMap extends StatelessWidget {
  const _RecipientRouteMap({required this.delivery});

  final Map<String, dynamic> delivery;

  @override
  Widget build(BuildContext context) {
    final route = _points(delivery['routePoints']);
    final dropoff = _point(delivery['dropoff']);
    final progress = _progress();
    final driverPoint = _interpolate(route, progress);
    final center = route.isNotEmpty
        ? route[route.length ~/ 2]
        : dropoff ?? const LatLng(11.5564, 104.9282);
    final vehicleType = delivery['vehicleType']?.toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
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
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              if (dropoff != null)
                Marker(
                  point: dropoff,
                  width: 42,
                  height: 42,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.danger,
                    size: 38,
                  ),
                ),
              if (driverPoint != null)
                Marker(
                  point: driverPoint,
                  width: 58,
                  height: 58,
                  child: Image.asset(
                    vehicleType == 'RICKSHAW'
                        ? 'assets/images/rickshaw_topview.png'
                        : 'assets/images/motorbike_topview.png',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _progress() {
    final stored = (delivery['simulationProgress'] as num?)?.toDouble() ?? 0;
    final startedRaw = delivery['simulationPhaseStartedAt']?.toString();
    if (startedRaw == null) return stored.clamp(0, 1);
    final started = DateTime.tryParse(startedRaw);
    if (started == null) return stored.clamp(0, 1);
    final duration =
        (delivery['simulationDurationSeconds'] as num?)?.toDouble() ?? 30;
    final elapsed = DateTime.now().difference(started).inMilliseconds / 1000;
    return (elapsed / duration).clamp(stored, 1).toDouble();
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

  static LatLng? _interpolate(List<LatLng> points, double progress) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;
    final scaled = progress * (points.length - 1);
    final lower = scaled.floor().clamp(0, points.length - 1);
    final upper = (lower + 1).clamp(0, points.length - 1);
    final fraction = scaled - lower;
    return LatLng(
      points[lower].latitude +
          (points[upper].latitude - points[lower].latitude) * fraction,
      points[lower].longitude +
          (points[upper].longitude - points[lower].longitude) * fraction,
    );
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
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
