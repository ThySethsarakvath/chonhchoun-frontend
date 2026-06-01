import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/driver_map_data.dart';
import 'driver_colors.dart';

class DriverLeafletMapCard extends StatefulWidget {
  const DriverLeafletMapCard({
    super.key,
    required this.interactive,
    required this.showAttribution,
    required this.overlay,
    this.pickupLatLng,
    this.dropOffLatLng,
  });

  final bool interactive;
  final bool showAttribution;
  final Widget overlay;
  final LatLng? pickupLatLng;
  final LatLng? dropOffLatLng;

  @override
  State<DriverLeafletMapCard> createState() => _DriverLeafletMapCardState();
}

class _DriverLeafletMapCardState extends State<DriverLeafletMapCard> {
  final _mapController = MapController();

  LatLng get _center {
    final p = widget.pickupLatLng;
    final d = widget.dropOffLatLng;
    if (p != null && d != null) {
      return LatLng((p.latitude + d.latitude) / 2, (p.longitude + d.longitude) / 2);
    }
    return p ?? d ?? driverMapCenter;
  }

  @override
  void didUpdateWidget(DriverLeafletMapCard old) {
    super.didUpdateWidget(old);
    _fitRoute();
  }

  void _fitRoute() {
    final p = widget.pickupLatLng;
    final d = widget.dropOffLatLng;
    if (p == null || d == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([p, d]),
          padding: const EdgeInsets.all(56),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final flags = widget.interactive
        ? InteractiveFlag.drag |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom
        : InteractiveFlag.none;

    final pickup = widget.pickupLatLng;
    final dropOff = widget.dropOffLatLng;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.interactive ? 13.5 : 13.0,
            interactionOptions: InteractionOptions(flags: flags),
            onMapReady: _fitRoute,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.chonhchoun.frontend',
            ),
            if (pickup != null && dropOff != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, dropOff],
                    color: DriverColors.blue,
                    strokeWidth: 3.5,
                  ),
                ],
              ),
            if (pickup != null || dropOff != null)
              MarkerLayer(
                markers: [
                  if (pickup != null)
                    Marker(
                      point: pickup,
                      width: 36,
                      height: 36,
                      child: _MapPin(color: DriverColors.danger, icon: Icons.location_on_rounded),
                    ),
                  if (dropOff != null)
                    Marker(
                      point: dropOff,
                      width: 36,
                      height: 36,
                      child: _MapPin(color: DriverColors.success, icon: Icons.circle_rounded),
                    ),
                ],
              ),
            if (widget.showAttribution)
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
          ],
        ),
        Positioned.fill(child: IgnorePointer(child: widget.overlay)),
      ],
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class DriverPreviewRouteOverlay extends StatelessWidget {
  const DriverPreviewRouteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: _DriverMapTag(
          title: 'Route Preview',
          subtitle: 'Pickup → Drop-off',
        ),
      ),
    );
  }
}

class DriverLiveMapOverlay extends StatelessWidget {
  const DriverLiveMapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _DriverMapTag(
          title: 'OpenStreetMap',
          subtitle: 'Live route',
        ),
      ),
    );
  }
}

class DriverProfileMapOverlay extends StatelessWidget {
  const DriverProfileMapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _DriverMapTag(
          title: 'Coverage Zone',
          subtitle: 'Phnom Penh',
          compact: true,
        ),
      ),
    );
  }
}

class _DriverMapTag extends StatelessWidget {
  const _DriverMapTag({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DriverColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: DriverColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
