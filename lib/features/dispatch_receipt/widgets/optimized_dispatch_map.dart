import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/data/map_data.dart';
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

class _OptimizedDispatchMapState extends State<OptimizedDispatchMap> {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  final Set<int> _reportedStops = {};
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _updateProgress(),
    );
  }

  @override
  void didUpdateWidget(covariant OptimizedDispatchMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.simulationStartedAt !=
        widget.receipt.simulationStartedAt) {
      _reportedStops.clear();
    }
    _updateProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateProgress() {
    final segmentStartedAt = widget.receipt.simulationSegmentStartedAt;
    var fullRouteProgress = widget.receipt.simulationProgress;
    if (widget.receipt.status == DispatchReceiptStatus.completed) {
      fullRouteProgress = 1;
    } else if (segmentStartedAt != null) {
      final elapsedMs = DateTime.now()
          .difference(segmentStartedAt)
          .inMilliseconds
          .toDouble();
      final durationMs = widget.receipt.simulationDurationSeconds * 1000.0;
      fullRouteProgress += elapsedMs / durationMs;
    }
    fullRouteProgress = fullRouteProgress.clamp(0.0, 1.0);
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

  List<LatLng> get _routePoints {
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

  ({LatLng point, double angle})? get _truckPosition {
    final points = _routePoints;
    if (points.length < 2) return null;

    final segmentLengths = <double>[];
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      final length = _distance.as(
        LengthUnit.Meter,
        points[index],
        points[index + 1],
      );
      segmentLengths.add(length);
      totalLength += length;
    }
    if (totalLength <= 0) return (point: points.first, angle: 0);

    var remaining = totalLength * _progress;
    for (var index = 0; index < segmentLengths.length; index += 1) {
      final segmentLength = segmentLengths[index];
      if (remaining <= segmentLength || index == segmentLengths.length - 1) {
        final fraction = segmentLength == 0
            ? 0.0
            : (remaining / segmentLength).clamp(0, 1);
        final from = points[index];
        final to = points[index + 1];
        final point = LatLng(
          from.latitude + (to.latitude - from.latitude) * fraction,
          from.longitude + (to.longitude - from.longitude) * fraction,
        );
        final angle = math.atan2(
          to.longitude - from.longitude,
          to.latitude - from.latitude,
        );
        return (point: point, angle: angle);
      }
      remaining -= segmentLength;
    }
    return (point: points.last, angle: 0);
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
                      point: truck.point,
                      width: 46,
                      height: 70,
                      child: Transform.rotate(
                        angle: truck.angle,
                        child: Image.asset(
                          'assets/images/truck_topview.png',
                          fit: BoxFit.contain,
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
