import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../colors/app_colors.dart';
import '../data/map_data.dart';

// ── Customer Map Picker ───────────────────────────────────────────────────────

class CustomerMapPicker extends StatelessWidget {
  const CustomerMapPicker({
    super.key,
    this.onMapTap,
    this.pickupLocation,
    this.dropoffLocation,
    this.routePoints,
    this.warehouseLocations,
    this.onWarehouseTap,
    required this.mapController,
  });

  final Function(LatLng)? onMapTap;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final List<LatLng>? routePoints;
  final List<LatLng>? warehouseLocations;
  final Function(LatLng)? onWarehouseTap;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: pickupLocation ?? const LatLng(11.5564, 104.9282),
        initialZoom: 14.0,
        onTap: onMapTap != null ? (tapPosition, point) => onMapTap!(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.chonhchoun.frontend',
        ),
        if (routePoints != null && routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints!,
                color: AppColors.blue,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (pickupLocation != null)
              Marker(
                point: pickupLocation!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.blue,
                  size: 40,
                ),
              ),
            if (dropoffLocation != null)
              Marker(
                point: dropoffLocation!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.danger,
                  size: 40,
                ),
              ),
            if (warehouseLocations != null)
              ...warehouseLocations!.map(
                (loc) => Marker(
                  point: loc,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => onWarehouseTap?.call(loc),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warehouse,
                        color: AppColors.blueDark,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Location Input Card ───────────────────────────────────────────────────────

class LocationInputCard extends StatelessWidget {
  const LocationInputCard({
    super.key,
    required this.pickupText,
    required this.dropoffText,
    required this.isSelectingPickup,
    required this.onSwitchMode,
  });

  final String pickupText;
  final String dropoffText;
  final bool isSelectingPickup;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationRow(
            icon: Icons.circle_outlined,
            color: AppColors.blue,
            label: "Pick-up point",
            value: pickupText,
            active: isSelectingPickup,
            onTap: isSelectingPickup ? null : onSwitchMode,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 20,
                color: AppColors.line,
              ),
            ),
          ),
          _buildLocationRow(
            icon: Icons.location_on,
            color: AppColors.danger,
            label: "Drop-off point",
            value: dropoffText,
            active: !isSelectingPickup,
            onTap: !isSelectingPickup ? null : onSwitchMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool active,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: active
            ? BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(Icons.gps_fixed, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Driver Leaflet Map Card ───────────────────────────────────────────────────

class DriverLeafletMapCard extends StatelessWidget {
  const DriverLeafletMapCard({
    super.key,
    required this.interactive,
    required this.showAttribution,
    required this.overlay,
  });

  final bool interactive;
  final bool showAttribution;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    final flags = interactive
        ? InteractiveFlag.drag |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom
        : InteractiveFlag.none;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: driverMapCenter,
            initialZoom: interactive ? 13.5 : 13.0,
            interactionOptions: InteractionOptions(flags: flags),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.chonhchoun.frontend',
            ),
            if (showAttribution)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(backgroundColor: Colors.white70, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(child: IgnorePointer(child: overlay)),
      ],
    );
  }
}

// ── Map Overlays ──────────────────────────────────────────────────────────────

class DriverPreviewRouteOverlay extends StatelessWidget {
  const DriverPreviewRouteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: _MapPlaceholderTag(
          title: 'Map Preview',
          subtitle: 'OpenStreetMap placeholder',
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
        child: _MapPlaceholderTag(
          title: 'OpenStreetMap',
          subtitle: 'Simple placeholder for next week',
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
        child: _MapPlaceholderTag(
          title: 'Coverage Zone',
          subtitle: 'Placeholder map',
          compact: true,
        ),
      ),
    );
  }
}

class _MapPlaceholderTag extends StatelessWidget {
  const _MapPlaceholderTag({
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
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
