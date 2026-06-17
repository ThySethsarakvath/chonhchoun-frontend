import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/data/map_data.dart';
import '../data/driver_map_data.dart';
import '../models/driver_route.dart';
import 'driver_colors.dart';

class DriverRouteMap extends StatefulWidget {
  const DriverRouteMap({super.key, required this.plan});

  final DriverRoutePlan plan;

  @override
  State<DriverRouteMap> createState() => _DriverRouteMapState();
}

class _DriverRouteMapState extends State<DriverRouteMap> {
  final MapController _controller = MapController();

  List<LatLng> get _allPoints {
    final points = <LatLng>[...widget.plan.geometry];
    final source = widget.plan.source?.point;
    if (source != null) points.add(source);
    for (final stop in widget.plan.stops) {
      if (stop.point != null) points.add(stop.point!);
    }
    return points;
  }

  LatLng get _center {
    final points = _allPoints;
    if (points.isEmpty) return driverMapCenter;
    double lat = 0;
    double lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  void _fit() {
    final points = _allPoints;
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(44),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(DriverRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fit();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final source = plan.source;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 12.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
        onMapReady: _fit,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.urlTemplate,
          userAgentPackageName: MapConfig.userAgent,
        ),
        if (plan.geometry.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: plan.geometry,
                strokeWidth: 5,
                color: DriverColors.blue,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (source != null)
              Marker(
                point: source.point,
                width: 40,
                height: 40,
                child: const _RouteMarker(
                  color: DriverColors.blueDark,
                  icon: Icons.warehouse_rounded,
                ),
              ),
            for (final stop in plan.stops)
              if (stop.point != null)
                Marker(
                  point: stop.point!,
                  width: 34,
                  height: 34,
                  child: _StopMarker(order: stop.order),
                ),
          ],
        ),
      ],
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DriverColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: DriverColors.success.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$order',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
