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

  /// Build a DriverRequest from a raw API map (packages endpoint).
  factory DriverRequest.fromApi(Map<String, dynamic> map) {
    final price = ((map['payment'] ?? {})['amount'] as num?)?.toDouble() ?? 
                  (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0;
    final itemType = (map['package'] ?? {})['type'] as String? ?? 'Package';
    final customerIdMap = map['customerId'] is Map ? map['customerId'] as Map<String, dynamic> : null;
    final customerName = map['customerName'] as String? ??
                         customerIdMap?['name'] as String? ??
                         'Customer';
    final initials = customerName.trim().isNotEmpty
        ? customerName.trim().split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase()
        : '??';

    return DriverRequest(
      id: map['_id'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      rawPrice: price,
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
      itemSummary: (map['package'] ?? {})['note'] as String? ?? '',
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
    );
  }
}
