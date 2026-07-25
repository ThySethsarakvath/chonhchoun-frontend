import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../colors/app_colors.dart';
import '../data/map_data.dart';
import '../theme/app_tokens.dart';

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
        onTap: onMapTap != null
            ? (tapPosition, point) => onMapTap!(point)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.urlTemplate,
          userAgentPackageName: MapConfig.userAgent,
        ),
        if (routePoints != null && routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints!,
                color: Colors.white,
                strokeWidth: 8,
              ),
              Polyline(
                points: routePoints!,
                color: AppColors.blue,
                strokeWidth: 5,
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
                child: const _MapPin(
                  color: AppColors.blue,
                  icon: Icons.trip_origin_rounded,
                  semanticLabel: 'Pickup location',
                ),
              ),
            if (dropoffLocation != null)
              Marker(
                point: dropoffLocation!,
                width: 60,
                height: 60,
                child: const _MapPin(
                  color: AppColors.danger,
                  icon: Icons.location_on_rounded,
                  semanticLabel: 'Drop-off location',
                ),
              ),
            if (warehouseLocations != null)
              ...warehouseLocations!.map(
                (loc) => Marker(
                  point: loc,
                  width: 50,
                  height: 50,
                  child: Semantics(
                    button: true,
                    label: 'Select warehouse',
                    child: Material(
                      color: AppColors.surfaceContainer,
                      elevation: 4,
                      shadowColor: AppColors.text.withValues(alpha: 0.18),
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.line),
                      ),
                      child: InkResponse(
                        onTap: () => onWarehouseTap?.call(loc),
                        radius: 25,
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: AppColors.blueDark,
                          size: 23,
                        ),
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

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.icon,
    required this.semanticLabel,
  });

  final Color color;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.28), width: 2),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
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
    return Material(
      color: AppColors.surfaceContainer,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLocationRow(
              context: context,
              icon: Icons.trip_origin_rounded,
              color: AppColors.blue,
              label: "Pick-up point",
              value: pickupText,
              active: isSelectingPickup,
              onTap: isSelectingPickup ? null : onSwitchMode,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 2, height: 12, color: AppColors.line),
              ),
            ),
            _buildLocationRow(
              context: context,
              icon: Icons.location_on_rounded,
              color: AppColors.danger,
              label: "Drop-off point",
              value: dropoffText,
              active: !isSelectingPickup,
              onTap: !isSelectingPickup ? null : onSwitchMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      selected: active,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.07) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? color : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Icon(Icons.gps_fixed_rounded, color: color, size: 18)
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
            ],
          ),
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
            initialCenter: MapConfig.driverMapCenter,
            initialZoom: interactive ? 13.5 : 13.0,
            interactionOptions: InteractionOptions(flags: flags),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.urlTemplate,
              userAgentPackageName: MapConfig.userAgent,
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
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
