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
        final decoded = json.decode(res.body);
        final list = decoded is Map && decoded.containsKey('data') 
            ? decoded['data'] as List<dynamic>
            : decoded as List<dynamic>;
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
        final decoded = json.decode(res.body);
        final list = decoded is Map && decoded.containsKey('data')
            ? decoded['data'] as List<dynamic>
            : decoded as List<dynamic>;
        return list.map((e) => DeliveryItem.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String _mapItemType(ItemType type) {
    switch (type) {
      case ItemType.document: return 'DOCUMENT';
      case ItemType.food: return 'FOOD';
      case ItemType.clothing: return 'CLOTHING';
      case ItemType.electronics: return 'ELECTRONICS';
      case ItemType.others: return 'OTHER';
    }
  }

  Future<DeliveryItem> createPackage(CustomerOrder order, String token) async {
    final payload = {
      'vehicleType': order.vehicleType == VehicleType.tuktuk ? 'CAR' : 'MOTORCYCLE',
      'package': {
        'name': order.itemName,
        'type': _mapItemType(order.itemType),
        'quantity': 1,
        'weightKg': order.weight > 0 ? order.weight : 0.1,
        'note': order.noteToDriver ?? '',
        'images': order.images ?? [],
      },
      'pickup': {
        'address': order.pickupAddress.isEmpty ? 'Current Location' : order.pickupAddress,
        'latitude': order.pickup.latitude,
        'longitude': order.pickup.longitude,
      },
      'dropoff': {
        'address': order.dropoffAddress.isEmpty ? 'Destination' : order.dropoffAddress,
        'latitude': order.dropoff.latitude,
        'longitude': order.dropoff.longitude,
        'contactName': (order.dropoffContactName == null || order.dropoffContactName!.isEmpty) ? 'Unknown' : order.dropoffContactName,
        'phone': (order.dropoffContactNumber == null || order.dropoffContactNumber!.isEmpty) ? '012345678' : order.dropoffContactNumber,
      },
      'payment': {
        'payer': 'SENDER',
        'method': order.paymentMethod == PaymentMethod.online ? 'ABA_QR' : 'CASH',
      }
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