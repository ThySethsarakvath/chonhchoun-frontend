import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_models.dart';
import '../models/order.dart';
import '../../global/base_url.dart';

class HomeService {
  String get _url => baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Packages / Deliveries ──────────────────────────────────────────────────
  
  Future<List<DeliveryItem>> fetchRecentDeliveries(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_url/packages/my'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.take(5).map((e) => DeliveryItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<DeliveryItem>> fetchDeliveryHistory(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_url/packages/my'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((e) => DeliveryItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<DeliveryItem> createPackage(CustomerOrder order, String token) async {
    final payload = {
      'itemName': order.itemName,
      'size': order.size.name, // S, M, L
      'weight': order.weight,
      'itemType': order.itemType.name,
      'vehicleType': order.vehicleType.name,
      'serviceType': order.serviceType.name,
      'itemHandling': order.itemHandling,
      'driverPickup': order.driverPickup,
      'pickupAddress': order.pickupAddress,
      'dropoffAddress': order.dropoffAddress,
      'pickupLat': order.pickup.latitude,
      'pickupLng': order.pickup.longitude,
      'dropoffLat': order.dropoff.latitude,
      'dropoffLng': order.dropoff.longitude,
      'price': order.price,
      'paymentMethod': order.paymentMethod.name,
      'dropoffContactName': order.dropoffContactName,
      'dropoffContactNumber': order.dropoffContactNumber,
      'noteToDriver': order.noteToDriver,
    };

    final res = await http.post(
      Uri.parse('$_url/packages'),
      headers: _headers(token),
      body: json.encode(payload),
    );

    if (res.statusCode == 201) {
      return DeliveryItem.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to create order: ${res.body}');
    }
  }

  // ── Promo banners ─────────────────────────────────────────────────────────
  
  Future<List<PromoBanner>> fetchBanners() async {
    // Currently no banners endpoint, returning mock data
    await Future.delayed(const Duration(milliseconds: 300));
    return HomeData.banners;
  }
}