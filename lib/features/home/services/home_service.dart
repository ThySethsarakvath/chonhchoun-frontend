import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_models.dart';
import '../../../global/base_url.dart';

/// All home-screen API calls.
/// Currently returns dummy data — swap the body of each method
/// once the backend endpoints are ready.
class HomeService {
  String get _url => baseUrl;

  static const _headers = {'Content-Type': 'application/json'};

  // ── Recent deliveries ─────────────────────────────────────────────────────
  // Future endpoint: GET /deliveries/recent?limit=5
  Future<List<DeliveryItem>> fetchRecentDeliveries() async {
    // TODO: uncomment when endpoint is ready
    // final res = await http.get(
    //   Uri.parse('$_url/deliveries/recent?limit=5'),
    //   headers: _headers,
    // );
    // if (res.statusCode == 200) {
    //   final list = json.decode(res.body) as List<dynamic>;
    //   return list.map((e) => DeliveryItem.fromJson(e)).toList();
    // }
    // throw Exception('Failed to load recent deliveries');

    // Dummy data
    await Future.delayed(const Duration(milliseconds: 600));
    return HomeData.recentDeliveries;
  }

  // ── Delivery history ──────────────────────────────────────────────────────
  // Future endpoint: GET /deliveries/history?page=1&limit=10
  Future<List<DeliveryItem>> fetchDeliveryHistory() async {
    // TODO: uncomment when endpoint is ready
    // final res = await http.get(
    //   Uri.parse('$_url/deliveries/history?page=1&limit=10'),
    //   headers: _headers,
    // );
    // if (res.statusCode == 200) {
    //   final list = json.decode(res.body) as List<dynamic>;
    //   return list.map((e) => DeliveryItem.fromJson(e)).toList();
    // }
    // throw Exception('Failed to load delivery history');

    await Future.delayed(const Duration(milliseconds: 600));
    return HomeData.deliveryHistory;
  }

  // ── Promo banners ─────────────────────────────────────────────────────────
  // Future endpoint: GET /banners?placement=home
  Future<List<PromoBanner>> fetchBanners() async {
    // TODO: uncomment when endpoint is ready
    // final res = await http.get(
    //   Uri.parse('$_url/banners?placement=home'),
    //   headers: _headers,
    // );
    // if (res.statusCode == 200) {
    //   final list = json.decode(res.body) as List<dynamic>;
    //   return list.map((e) => PromoBanner.fromJson(e)).toList();
    // }
    // throw Exception('Failed to load banners');

    await Future.delayed(const Duration(milliseconds: 300));
    return HomeData.banners;
  }
}