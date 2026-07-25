import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/data/map_data.dart';
import '../../../shared/utils/route_motion.dart';
import '../models/dispatch_receipt_models.dart';

class OptimizedDispatchMap extends StatefulWidget {
  const OptimizedDispatchMap({
    super.key,
    required this.receipt,
    this.onStopReached,
  });

  final DispatchReceipt receipt;
  final ValueChanged<int>? onStopReached;

  @override
  State<OptimizedDispatchMap> createState() => _OptimizedDispatchMapState();
}

class _OptimizedDispatchMapState extends State<OptimizedDispatchMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final SmoothRouteProgress _progressSmoother = SmoothRouteProgress();
  final Set<int> _reportedStops = {};
  late final AnimationController _frameController;
  late List<LatLng> _cachedRoutePoints;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _cachedRoutePoints = _resolveRoutePoints();
    _updateProgress();
    _frameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_updateProgress)
          ..repeat();
  }

  @override
  void didUpdateWidget(covariant OptimizedDispatchMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.simulationStartedAt !=
        widget.receipt.simulationStartedAt) {
      _reportedStops.clear();
    }
    if (!identical(
          oldWidget.receipt.routeGeometry,
          widget.receipt.routeGeometry,
        ) ||
        !identical(oldWidget.receipt.stops, widget.receipt.stops)) {
      _cachedRoutePoints = _resolveRoutePoints();
    }
    _updateProgress();
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final segmentStartedAt = widget.receipt.simulationSegmentStartedAt;
    final completed = widget.receipt.status == DispatchReceiptStatus.completed;
    final simulationStarted = widget.receipt.simulationStartedAt != null;
    final fullRouteProgress = _progressSmoother.update(
      phaseKey:
          '${widget.receipt.id}:'
          '${widget.receipt.simulationStartedAt?.millisecondsSinceEpoch ?? 'ready'}',
      serverProgress: widget.receipt.simulationProgress,
      durationSeconds: widget.receipt.simulationDurationSeconds,
      completed: completed,
      paused: !simulationStarted || segmentStartedAt == null,
    );
    final viewerEnd = widget.receipt.viewerRouteEndProgress.clamp(0.05, 1.0);
    final nextProgress = (fullRouteProgress / viewerEnd).clamp(0.0, 1.0);

    if (mounted && nextProgress != _progress) {
      setState(() => _progress = nextProgress);
    }
    _reportReachedStops(fullRouteProgress);
  }

  void _reportReachedStops(double progress) {
    if (widget.onStopReached == null ||
        widget.receipt.simulationStartedAt == null) {
      return;
    }
    final routeDuration =
        widget.receipt.estimatedDurationSeconds?.toDouble() ?? 0;

    final orderedStops = [...widget.receipt.stops]
      ..sort((left, right) => left.stopOrder.compareTo(right.stopOrder));
    final pendingIndex = orderedStops.indexWhere(
      (stop) => stop.status == DispatchReceiptStopStatus.pending,
    );
    if (pendingIndex < 0) return;

    final stop = orderedStops[pendingIndex];
    if (_reportedStops.contains(stop.stopOrder)) return;
    final estimated = stop.estimatedArrivalSeconds?.toDouble();
    final threshold = stop.routeProgress != null
        ? stop.routeProgress!.clamp(0.05, 1.0)
        : estimated != null && routeDuration > 0
        ? (estimated / routeDuration).clamp(0.05, 1.0)
        : (pendingIndex + 1) / orderedStops.length;
    if (progress >= threshold && _reportedStops.add(stop.stopOrder)) {
      widget.onStopReached!(stop.stopOrder);
    }
  }

  bool _isValidPoint(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  LatLng? _safePoint(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    final point = LatLng(latitude, longitude);
    return _isValidPoint(point) ? point : null;
  }

  List<LatLng> _resolveRoutePoints() {
    final decoded = widget.receipt.routeGeometry
        .where(_isValidPoint)
        .toList(growable: false);
    if (decoded.length >= 2) return decoded;

    final fallback = <LatLng>[];
    final source = widget.receipt.sourceBranch;
    final sourcePoint = _safePoint(source.lat, source.lng);
    if (sourcePoint != null) fallback.add(sourcePoint);

    final orderedStops = [...widget.receipt.stops]
      ..sort((left, right) => left.stopOrder.compareTo(right.stopOrder));
    for (final stop in orderedStops) {
      final branch = stop.destinationBranch;
      final point = _safePoint(branch.lat, branch.lng);
      if (point != null) fallback.add(point);
    }
    return fallback;
  }

  List<LatLng> get _routePoints => _cachedRoutePoints;

  List<LatLng> get _allPoints {
    final points = <LatLng>[..._routePoints];
    final source = widget.receipt.sourceBranch;
    final sourcePoint = _safePoint(source.lat, source.lng);
    if (sourcePoint != null) points.add(sourcePoint);
    for (final stop in widget.receipt.stops) {
      final branch = stop.destinationBranch;
      final point = _safePoint(branch.lat, branch.lng);
      if (point != null) points.add(point);
    }
    return points;
  }

  void _fitRoute() {
    final points = _allPoints;
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  void _changeZoom(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(3, 18));
  }

  RouteMotionSnapshot? get _truckPosition {
    final points = _routePoints;
    return sampleRouteMotion(points, _progress);
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.receipt.sourceBranch;
    final sourcePoint = _safePoint(source.lat, source.lng);
    final routePoints = _routePoints;
    final truck = _truckPosition;
    final simulationStarted = widget.receipt.simulationStartedAt != null;
    final simulationPaused =
        simulationStarted &&
        widget.receipt.simulationSegmentStartedAt == null &&
        widget.receipt.status != DispatchReceiptStatus.completed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routePoints.isNotEmpty
                  ? routePoints.first
                  : MapConfig.driverMapCenter,
              initialZoom: 8,
              onMapReady: _fitRoute,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
              ),
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
                      strokeWidth: 7,
                      color: const Color(0xFF2563EB),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (sourcePoint != null)
                    Marker(
                      point: sourcePoint,
                      width: 44,
                      height: 44,
                      child: const _WarehouseMarker(
                        color: Color(0xFF0F172A),
                        label: 'S',
                      ),
                    ),
                  for (final stop in widget.receipt.stops)
                    if (_safePoint(
                          stop.destinationBranch.lat,
                          stop.destinationBranch.lng,
                        )
                        case final stopPoint?)
                      Marker(
                        point: stopPoint,
                        width: 40,
                        height: 40,
                        child: _WarehouseMarker(
                          color:
                              stop.status ==
                                      DispatchReceiptStopStatus.confirmed ||
                                  stop.status ==
                                      DispatchReceiptStopStatus.partial
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF97316),
                          label: '${stop.stopOrder}',
                        ),
                      ),
                  if (truck != null)
                    Marker(
                      point: truck.position,
                      width: 46,
                      height: 70,
                      child: Transform.rotate(
                        angle: truck.bearingRadians,
                        child: Image.asset(
                          'assets/images/truck_topview.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Column(
              children: [
                _MapControlButton(
                  tooltip: 'Zoom in',
                  icon: Icons.add_rounded,
                  onPressed: () => _changeZoom(1),
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  tooltip: 'Zoom out',
                  icon: Icons.remove_rounded,
                  onPressed: () => _changeZoom(-1),
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  tooltip: 'Fit route',
                  icon: Icons.route_rounded,
                  onPressed: _fitRoute,
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                MapConfig.attributionLabel,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    simulationStarted
                        ? Icons.local_shipping_rounded
                        : Icons.route_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          simulationPaused
                              ? 'Waiting for branch confirmation'
                              : simulationStarted
                              ? 'Simulation ${(_progress * 100).round()}%'
                              : 'Optimized route ready',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: _progress,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
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

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        color: const Color(0xFF0F172A),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _WarehouseMarker extends StatelessWidget {
  const _WarehouseMarker({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
