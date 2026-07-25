import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../shared/colors/app_colors.dart';
import '../../../shared/data/map_data.dart';
import '../../../shared/theme/app_tokens.dart';

class PickupMapPicker extends StatefulWidget {
  const PickupMapPicker({
    super.key,
    required this.initialLocation,
    this.initialAddress,
    required this.warehouseLocation,
  });

  final LatLng initialLocation;
  final String? initialAddress;
  final LatLng warehouseLocation;

  @override
  State<PickupMapPicker> createState() => _PickupMapPickerState();
}

class _PickupMapPickerState extends State<PickupMapPicker> {
  late LatLng _selected;
  String? _address;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
    _address = widget.initialAddress;
    if (_address == null) {
      _reverseGeocode(_selected);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}',
      );
      final response = await http.get(
        url,
        headers: const {'User-Agent': 'chonhchoun-app'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _address =
              (body['display_name'] as String?) ??
              '${point.latitude.toStringAsFixed(6)}, '
                  '${point.longitude.toStringAsFixed(6)}';
        });
      } else {
        setState(() {
          _address =
              '${point.latitude.toStringAsFixed(6)}, '
              '${point.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (_) {
      setState(() {
        _address =
            '${point.latitude.toStringAsFixed(6)}, '
            '${point.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  void _saveSelection() {
    Navigator.of(context).pop({'latlng': _selected, 'address': _address});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              onTap: (tapPosition, latlng) async {
                setState(() => _selected = latlng);
                await _reverseGeocode(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.urlTemplate,
                userAgentPackageName: MapConfig.userAgent,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.warehouseLocation,
                    width: 52,
                    height: 52,
                    child: const _PickerMarker(
                      icon: Icons.warehouse_rounded,
                      color: AppColors.danger,
                      semanticLabel: 'Warehouse location',
                    ),
                  ),
                  Marker(
                    point: _selected,
                    width: 52,
                    height: 52,
                    child: const _PickerMarker(
                      icon: Icons.my_location_rounded,
                      color: AppColors.blue,
                      semanticLabel: 'Selected pickup location',
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.customerContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _PickerHeader(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.customerContentMaxWidth,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppShadows.floating,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.softBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_searching_rounded,
                              color: AppColors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected pickup',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  'Tap anywhere on the map to adjust',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedSwitcher(
                        duration: AppMotion.standard,
                        child: _loadingAddress
                            ? const LinearProgressIndicator(
                                key: ValueKey('loading'),
                                minHeight: 3,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppRadius.pill),
                                ),
                              )
                            : Text(
                                _address ??
                                    '${_selected.latitude}, '
                                        '${_selected.longitude}',
                                key: const ValueKey('address'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadingAddress
                                  ? null
                                  : _saveSelection,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Use location'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
                boxShadow: AppShadows.card,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.blueDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.card,
            ),
            child: Text(
              'Select pickup location',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerMarker extends StatelessWidget {
  const _PickerMarker({
    required this.icon,
    required this.color,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: AppShadows.card,
        ),
        child: Icon(icon, color: color, size: 23),
      ),
    );
  }
}
