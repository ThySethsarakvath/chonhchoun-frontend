import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/data/map_data.dart';
import '../../../shared/models/driver_request.dart';
import '../../../shared/widgets/driver_colors.dart';

class ExpressDriverRouteMap extends StatefulWidget {
  const ExpressDriverRouteMap({
    required this.request,
    this.onFocus,
    this.borderRadius = 22,
    super.key,
  });

  final DriverRequest request;
  final VoidCallback? onFocus;
  final double borderRadius;

  @override
  State<ExpressDriverRouteMap> createState() => _ExpressDriverRouteMapState();
}

class _ExpressDriverRouteMapState extends State<ExpressDriverRouteMap> {
  final MapController _controller = MapController();
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted &&
          (widget.request.status == 'ACCEPTED' ||
              widget.request.status == 'IN_TRANSIT')) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  List<LatLng> get _allPoints => [
    if (widget.request.driverStartLocation != null)
      widget.request.driverStartLocation!,
    ...widget.request.pickupRoutePoints,
    ...widget.request.deliveryRoutePoints,
    widget.request.pickupLatLng,
    widget.request.dropOffLatLng,
  ];

  @override
  void didUpdateWidget(ExpressDriverRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.status != widget.request.status) _fitRoute();
  }

  void _fitRoute() {
    final points = _allPoints;
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final isPending = request.status == null || request.status == 'PENDING';
    final pickupActive =
        request.status == 'ACCEPTED' || request.status == 'ARRIVED_AT_PICKUP';
    final movingPoint = isPending ? null : request.simulatedLocation;
    final center = movingPoint ?? request.pickupLatLng;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                onMapReady: _fitRoute,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all | InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.urlTemplate,
                  userAgentPackageName: MapConfig.userAgent,
                ),
                PolylineLayer(
                  polylines: [
                    if (request.pickupRoutePoints.length >= 2)
                      Polyline(
                        points: request.pickupRoutePoints,
                        strokeWidth: pickupActive ? 6 : 4,
                        color: pickupActive
                            ? DriverColors.blue
                            : DriverColors.muted.withValues(alpha: 0.45),
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    if (request.deliveryRoutePoints.length >= 2)
                      Polyline(
                        points: request.deliveryRoutePoints,
                        strokeWidth: pickupActive ? 4 : 6,
                        color: isPending
                            ? DriverColors.blue
                            : pickupActive
                            ? DriverColors.muted.withValues(alpha: 0.45)
                            : DriverColors.success,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (request.driverStartLocation != null)
                      Marker(
                        point: request.driverStartLocation!,
                        width: 34,
                        height: 34,
                        child: const _PointMarker(
                          icon: Icons.person_pin_circle_rounded,
                          color: DriverColors.blueDark,
                        ),
                      ),
                    Marker(
                      point: request.pickupLatLng,
                      width: 38,
                      height: 38,
                      child: const _PointMarker(
                        icon: Icons.inventory_2_rounded,
                        color: DriverColors.blue,
                      ),
                    ),
                    Marker(
                      point: request.dropOffLatLng,
                      width: 40,
                      height: 40,
                      child: const _PointMarker(
                        icon: Icons.location_on_rounded,
                        color: DriverColors.danger,
                      ),
                    ),
                    if (movingPoint != null)
                      Marker(
                        point: movingPoint,
                        width: 64,
                        height: 64,
                        child: Container(
                          padding: const EdgeInsets.all(4),
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
                            request.vehicleType == 'RICKSHAW'
                                ? 'assets/images/rickshaw_topview.png'
                                : 'assets/images/motorbike_topview.png',
                          ),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onFocus != null)
            Positioned(
              right: 12,
              bottom: 28,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Focus map',
                onPressed: widget.onFocus,
                backgroundColor: Colors.white,
                foregroundColor: DriverColors.blueDark,
                child: const Icon(Icons.fullscreen_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _PointMarker extends StatelessWidget {
  const _PointMarker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }
}
