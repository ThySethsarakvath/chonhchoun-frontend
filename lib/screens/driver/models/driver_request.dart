import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DriverRequest {
  const DriverRequest({
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
  });

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
}
