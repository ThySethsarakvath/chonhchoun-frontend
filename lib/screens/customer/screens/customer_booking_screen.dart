import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Use http package
import 'package:geolocator/geolocator.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/home_models.dart';
import '../../../shared/models/warehouse.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/widgets/app_map_widgets.dart';
import '../../../shared/data/warehouse_data.dart';
import '../../../shared/theme/app_tokens.dart';
import 'customer_item_info_screen.dart';

class CustomerBookingScreen extends StatefulWidget {
  const CustomerBookingScreen({
    super.key,
    required this.onOrderCreated,
    required this.serviceType,
  });

  final Future<DeliveryItem?> Function(CustomerOrder) onOrderCreated;
  final DeliveryServiceType serviceType;

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  LatLng? _pickupLocation;
  String? _pickupName;
  LatLng? _dropoffLocation;
  String? _dropoffName;
  bool _isSelectingPickup = true;
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    LatLng userLoc = const LatLng(11.5710, 104.8990); // Default to ITC PP
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          userLoc = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      debugPrint("Error getting live location: $e");
    }

    _userLocation = userLoc;

    setState(() {
      if (widget.serviceType == DeliveryServiceType.express) {
        _pickupLocation = null;
        _pickupName = null;
        _isSelectingPickup = true;
      } else {
        final closest = _findClosestWarehouse(userLoc);
        _pickupLocation = closest.location;
        _pickupName = closest.name;
        _isSelectingPickup = false; // Immediately prompt destination selection
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_pickupLocation ?? userLoc, 15);
      }
    });
  }

  Warehouse _findClosestWarehouse(LatLng userLoc) {
    Warehouse closest = WarehouseData.allWarehouses.first;
    double minDistance = double.infinity;

    for (var w in WarehouseData.allWarehouses) {
      double dist = Geolocator.distanceBetween(
        userLoc.latitude,
        userLoc.longitude,
        w.location.latitude,
        w.location.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = w;
      }
    }
    return closest;
  }

  String _formatLocation(LatLng? loc, String? name) {
    if (name != null) return name;
    if (loc == null) {
      return widget.serviceType == DeliveryServiceType.express
          ? "Center pin on location"
          : "Select warehouse";
    }
    return "${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}";
  }

  Future<void> _confirmCenterLocation() async {
    if (widget.serviceType == DeliveryServiceType.warehouse) {
      _showWarehousePicker();
      return;
    }

    final point = _mapController.camera.center;
    setState(() => _isResolvingLocation = true);
    final address = await _reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = point;
        _pickupName = address;
        if (_dropoffLocation == null) {
          _isSelectingPickup = false;
        }
      } else {
        _dropoffLocation = point;
        _dropoffName = address;
      }
      _isResolvingLocation = false;
    });

    if (_pickupLocation != null && _dropoffLocation != null) {
      _fetchRoute();
    }
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'chonhchoun-app'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final displayName = body['display_name']?.toString().trim();
        if (displayName?.isNotEmpty == true) return displayName!;
      }
    } catch (_) {
      // Coordinates remain a reliable fallback when geocoding is unavailable.
    }
    return '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
  }

  void _showWarehousePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSelectingPickup
                      ? "Select Drop-off Warehouse"
                      : "Select Destination Warehouse",
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Choose one of our Chonhchoun warehouses",
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    itemCount: WarehouseData.allWarehouses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final warehouse = WarehouseData.allWarehouses[index];
                      return Material(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: InkWell(
                          onTap: () {
                            final point = warehouse.location;
                            setState(() {
                              if (_isSelectingPickup) {
                                _pickupLocation = point;
                                _pickupName = warehouse.name;
                                _isSelectingPickup = false;
                              } else {
                                _dropoffLocation = point;
                                _dropoffName = warehouse.name;
                              }
                            });
                            _mapController.move(point, 15);
                            Navigator.pop(context);
                            if (_pickupLocation != null &&
                                _dropoffLocation != null) {
                              _fetchRoute();
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.softBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.warehouse_rounded,
                                    color: AppColors.blue,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    warehouse.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleWarehouseMarkerTap(LatLng loc) {
    final warehouse = WarehouseData.allWarehouses.firstWhere(
      (w) => w.location == loc,
    );
    setState(() {
      if (_isSelectingPickup) {
        _pickupLocation = loc;
        _pickupName = warehouse.name;
        _isSelectingPickup = false;
      } else {
        _dropoffLocation = loc;
        _dropoffName = warehouse.name;
      }
    });
    if (_pickupLocation != null && _dropoffLocation != null) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_pickupLocation!.longitude},${_pickupLocation!.latitude};${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          _routePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  void _openPackageDetails() {
    final pickup = _pickupLocation;
    final dropoff = _dropoffLocation;
    if (pickup == null || dropoff == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerItemInfoScreen(
          pickup: pickup,
          dropoff: dropoff,
          pickupAddress: _pickupName ?? _formatLocation(pickup, null),
          dropoffAddress: _dropoffName ?? _formatLocation(dropoff, null),
          serviceType: widget.serviceType,
          onOrderCreated: widget.onOrderCreated,
          userLocation: _userLocation ?? const LatLng(11.5710, 104.8990),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBothLocations =
        _pickupLocation != null && _dropoffLocation != null;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          CustomerMapPicker(
            mapController: _mapController,
            pickupLocation: _pickupLocation,
            dropoffLocation: _dropoffLocation,
            routePoints: _routePoints,
            warehouseLocations:
                widget.serviceType == DeliveryServiceType.warehouse
                ? WarehouseData.allWarehouses.map((w) => w.location).toList()
                : null,
            onWarehouseTap: _handleWarehouseMarkerTap,
          ),

          if (widget.serviceType == DeliveryServiceType.express)
            _CenterSelectionPin(isPickup: _isSelectingPickup),

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BookingMapHeader(
                        serviceType: widget.serviceType,
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LocationInputCard(
                        pickupText: _formatLocation(
                          _pickupLocation,
                          _pickupName,
                        ),
                        dropoffText: _formatLocation(
                          _dropoffLocation,
                          _dropoffName,
                        ),
                        isSelectingPickup: _isSelectingPickup,
                        onSwitchMode: () => setState(
                          () => _isSelectingPickup = !_isSelectingPickup,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: AppSpacing.md,
            bottom:
                bottomInset + (hasBothLocations ? 190 : 126) + AppSpacing.sm,
            child: _MapControlButton(
              tooltip: 'Recenter map',
              icon: Icons.my_location_rounded,
              onTap: () {
                final target = _pickupLocation ?? _userLocation;
                if (target != null) {
                  _mapController.move(target, 15);
                }
              },
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
                child: _BookingActionPanel(
                  isPickup: _isSelectingPickup,
                  pickupSelected: _pickupLocation != null,
                  dropoffSelected: _dropoffLocation != null,
                  isResolving: _isResolvingLocation,
                  onConfirmLocation: _confirmCenterLocation,
                  onContinue: hasBothLocations ? _openPackageDetails : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingMapHeader extends StatelessWidget {
  const _BookingMapHeader({required this.serviceType, required this.onBack});

  final DeliveryServiceType serviceType;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isExpress = serviceType == DeliveryServiceType.express;
    return Row(
      children: [
        _MapControlButton(
          tooltip: 'Back',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Book a delivery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isExpress
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.softBlue,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isExpress ? 'Express' : 'Warehouse',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isExpress ? AppColors.warning : AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterSelectionPin extends StatelessWidget {
  const _CenterSelectionPin({required this.isPickup});

  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    final color = isPickup ? AppColors.blue : AppColors.danger;
    return Center(
      child: IgnorePointer(
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: AnimatedSwitcher(
            duration: AppMotion.standard,
            child: Column(
              key: ValueKey(isPickup),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.text.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    isPickup ? 'Pickup point' : 'Drop-off point',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Icon(Icons.location_on_rounded, size: 48, color: color),
                Container(
                  width: 10,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.text.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.surfaceContainer,
          elevation: 0,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.card,
              ),
              child: Icon(icon, color: AppColors.blueDark, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingActionPanel extends StatelessWidget {
  const _BookingActionPanel({
    required this.isPickup,
    required this.pickupSelected,
    required this.dropoffSelected,
    required this.isResolving,
    required this.onConfirmLocation,
    required this.onContinue,
  });

  final bool isPickup;
  final bool pickupSelected;
  final bool dropoffSelected;
  final bool isResolving;
  final VoidCallback onConfirmLocation;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final currentSelected = isPickup ? pickupSelected : dropoffSelected;
    final locationLabel = isPickup
        ? currentSelected
              ? 'Update pickup location'
              : 'Confirm pickup location'
        : currentSelected
        ? 'Update drop-off location'
        : 'Confirm drop-off location';
    final accent = isPickup ? AppColors.blue : AppColors.danger;

    return AnimatedSize(
      duration: AppMotion.emphasized,
      curve: AppMotion.standardCurve,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onContinue != null) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Confirm Selection'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blueDark,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            SizedBox(
              width: double.infinity,
              height: onContinue == null ? 54 : 46,
              child: onContinue == null
                  ? ElevatedButton.icon(
                      onPressed: isResolving ? null : onConfirmLocation,
                      icon: isResolving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPickup
                                  ? Icons.trip_origin_rounded
                                  : Icons.location_on_rounded,
                            ),
                      label: Text(
                        isResolving ? 'Finding address…' : locationLabel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: isResolving ? null : onConfirmLocation,
                      icon: Icon(
                        isPickup
                            ? Icons.edit_location_alt_outlined
                            : Icons.edit_location_outlined,
                      ),
                      label: Text(locationLabel),
                      style: TextButton.styleFrom(foregroundColor: accent),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
