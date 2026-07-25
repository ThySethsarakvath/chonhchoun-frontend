import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DriverRequest {
  const DriverRequest({
    // Demo / display fields
    required this.title,
    required this.recipient,
    required this.pickup,
    required this.dropOff,
    required this.pickupLatLng,
    required this.dropOffLatLng,
    required this.payment,
    required this.fee,
    required this.phone,
    required this.eta,
    required this.deliveries,
    required this.rating,
    required this.accent,
    required this.itemSummary,
    required this.senderInitials,
    // Backend fields (optional, populated when from API)
    this.id,
    this.status,
    this.rawPrice,
    this.vehicleType = 'MOTORCYCLE',
    this.quantity = 1,
    this.driverStartLocation,
    this.pickupRoutePoints = const [],
    this.deliveryRoutePoints = const [],
    this.simulationProgress = 0,
    this.simulationDurationSeconds = 30,
    this.simulationPhaseStartedAt,
  });

  // ── Demo / UI display fields ──────────────────────────────────────────────
  final String title;
  final String recipient;
  final String pickup;
  final String dropOff;
  final LatLng pickupLatLng;
  final LatLng dropOffLatLng;
  final String payment;
  final String fee;
  final String phone;
  final String eta;
  final int deliveries;
  final double rating;
  final Color accent;
  final String itemSummary;
  final String senderInitials;

  // ── Backend fields ────────────────────────────────────────────────────────
  final String? id;
  final String? status;
  final double? rawPrice;
  final String vehicleType;
  final int quantity;
  final LatLng? driverStartLocation;
  final List<LatLng> pickupRoutePoints;
  final List<LatLng> deliveryRoutePoints;
  final double simulationProgress;
  final int simulationDurationSeconds;
  final DateTime? simulationPhaseStartedAt;

  /// Build a DriverRequest from a raw API map (packages endpoint).
  factory DriverRequest.fromApi(Map<String, dynamic> map) {
    final price =
        ((map['payment'] ?? {})['amount'] as num?)?.toDouble() ??
        (map['estimatedPrice'] as num?)?.toDouble() ??
        0.0;
    final itemType = (map['package'] ?? {})['type'] as String? ?? 'Package';
    final itemName = (map['package'] ?? {})['name'] as String? ?? 'Package';
    final quantity = ((map['package'] ?? {})['quantity'] as num?)?.toInt() ?? 1;
    final customerIdMap = map['customerId'] is Map
        ? map['customerId'] as Map<String, dynamic>
        : null;
    final customerName =
        map['customerName'] as String? ??
        customerIdMap?['name'] as String? ??
        'Customer';
    final initials = customerName.trim().isNotEmpty
        ? customerName
              .trim()
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
        : '??';

    return DriverRequest(
      id: map['_id'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      rawPrice: price,
      vehicleType: map['vehicleType']?.toString() ?? 'MOTORCYCLE',
      quantity: quantity,
      driverStartLocation: _point(map['driverStartLocation']),
      pickupRoutePoints: _points(map['pickupRoutePoints']),
      deliveryRoutePoints: _points(map['deliveryRoutePoints']),
      simulationProgress: (map['simulationProgress'] as num?)?.toDouble() ?? 0,
      simulationDurationSeconds:
          (map['simulationDurationSeconds'] as num?)?.toInt() ?? 30,
      simulationPhaseStartedAt: map['simulationPhaseStartedAt'] != null
          ? DateTime.tryParse(map['simulationPhaseStartedAt'].toString())
          : null,
      // ── Display
      title: itemType,
      recipient: customerName,
      pickup: (map['pickup'] ?? {})['address'] as String? ?? '',
      dropOff: (map['dropoff'] ?? {})['address'] as String? ?? '',
      pickupLatLng: LatLng(
        ((map['pickup'] ?? {})['latitude'] as num?)?.toDouble() ?? 11.5625,
        ((map['pickup'] ?? {})['longitude'] as num?)?.toDouble() ?? 104.9160,
      ),
      dropOffLatLng: LatLng(
        ((map['dropoff'] ?? {})['latitude'] as num?)?.toDouble() ?? 11.5625,
        ((map['dropoff'] ?? {})['longitude'] as num?)?.toDouble() ?? 104.9160,
      ),
      payment: (map['payment'] ?? {})['method'] as String? ?? 'Cash',
      fee: '\$${price.toStringAsFixed(2)}',
      phone: (map['dropoff'] ?? {})['phone'] as String? ?? '',
      eta: '~20 mins',
      deliveries: 0,
      rating: 0,
      accent: const Color(0xFF2B6D9B),
      itemSummary: '$itemName · $quantity package(s)',
      senderInitials: initials,
    );
  }

  /// Returns a copy with an updated status.
  DriverRequest copyWithStatus(String newStatus) {
    return DriverRequest(
      title: title,
      recipient: recipient,
      pickup: pickup,
      dropOff: dropOff,
      pickupLatLng: pickupLatLng,
      dropOffLatLng: dropOffLatLng,
      payment: payment,
      fee: fee,
      phone: phone,
      eta: eta,
      deliveries: deliveries,
      rating: rating,
      accent: accent,
      itemSummary: itemSummary,
      senderInitials: senderInitials,
      id: id,
      status: newStatus,
      rawPrice: rawPrice,
      vehicleType: vehicleType,
      quantity: quantity,
      driverStartLocation: driverStartLocation,
      pickupRoutePoints: pickupRoutePoints,
      deliveryRoutePoints: deliveryRoutePoints,
      simulationProgress: simulationProgress,
      simulationDurationSeconds: simulationDurationSeconds,
      simulationPhaseStartedAt: simulationPhaseStartedAt,
    );
  }

  List<LatLng> get activeRoutePoints {
    if (status == 'ACCEPTED' || status == 'ARRIVED_AT_PICKUP') {
      return pickupRoutePoints;
    }
    return deliveryRoutePoints;
  }

  double get effectiveProgress {
    if (status == 'ARRIVED_AT_PICKUP' ||
        status == 'ARRIVED_AT_DROPOFF' ||
        status == 'DELIVERED') {
      return 1;
    }
    final startedAt = simulationPhaseStartedAt;
    if (startedAt == null) return simulationProgress.clamp(0, 1).toDouble();
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds / 1000;
    return (elapsed / simulationDurationSeconds)
        .clamp(simulationProgress, 1)
        .toDouble();
  }

  LatLng? get simulatedLocation {
    final points = activeRoutePoints;
    if (points.isEmpty) return driverStartLocation;
    if (points.length == 1) return points.first;
    final scaled = effectiveProgress * (points.length - 1);
    final lower = scaled.floor().clamp(0, points.length - 1);
    final upper = (lower + 1).clamp(0, points.length - 1);
    final fraction = scaled - lower;
    return LatLng(
      points[lower].latitude +
          (points[upper].latitude - points[lower].latitude) * fraction,
      points[lower].longitude +
          (points[upper].longitude - points[lower].longitude) * fraction,
    );
  }

  static List<LatLng> _points(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(_point).whereType<LatLng>().toList();
  }

  static LatLng? _point(dynamic raw) {
    if (raw is! Map) return null;
    final latitude = raw['latitude'] as num?;
    final longitude = raw['longitude'] as num?;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }
}
