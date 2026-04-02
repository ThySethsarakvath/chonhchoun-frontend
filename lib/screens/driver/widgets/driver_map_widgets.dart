import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/driver_map_data.dart';
import 'driver_colors.dart';

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
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
          ],
        ),
        Positioned.fill(child: IgnorePointer(child: overlay)),
      ],
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
        child: _DriverMapPlaceholderTag(
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
        child: _DriverMapPlaceholderTag(
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
        child: _DriverMapPlaceholderTag(
          title: 'Coverage Zone',
          subtitle: 'Placeholder map',
          compact: true,
        ),
      ),
    );
  }
}

class _DriverMapPlaceholderTag extends StatelessWidget {
  const _DriverMapPlaceholderTag({
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
