import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'customer_colors.dart';

class CustomerMapPicker extends StatelessWidget {
  const CustomerMapPicker({
    super.key,
    required this.onMapTap,
    this.pickupLocation,
    this.dropoffLocation,
    required this.mapController,
  });

  final Function(LatLng) onMapTap;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: pickupLocation ?? const LatLng(11.5564, 104.9282),
        initialZoom: 14.0,
        onTap: (tapPosition, point) => onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.chonhchoun.frontend',
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
                  color: CustomerColors.blue,
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
                  color: CustomerColors.danger,
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

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
            color: CustomerColors.blue,
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
                color: CustomerColors.line,
              ),
            ),
          ),
          _buildLocationRow(
            icon: Icons.location_on,
            color: CustomerColors.danger,
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
                      color: CustomerColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: CustomerColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(Icons.gps_fixed, color: CustomerColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
