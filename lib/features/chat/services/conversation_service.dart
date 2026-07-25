import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../models/conversation.dart';

/// Builds the per-role list of deliveries that have a chat
/// (a delivery is chattable once a driver is assigned).
class ConversationService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Customer: their own bookings that already have a driver assigned.
  Future<List<Conversation>> customerConversations(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/packages/my?limit=50'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('មិនអាចផ្ទុកបញ្ជីសន្ទនាបានទេ (${res.statusCode})');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>? ?? []);
    return data
        .where((p) => p['driverId'] != null)
        .map(
          (p) => Conversation(
            packageId: (p['_id'] ?? '').toString(),
            trackingNumber: (p['trackingNumber'] ?? '').toString(),
            status: (p['status'] ?? '').toString(),
            peerName: 'អ្នកដឹកជញ្ជូន', // "Driver"
          ),
        )
        .toList();
  }

  /// Driver: packages assigned to them.
  Future<List<Conversation>> driverConversations(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/packages/assigned'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('មិនអាចផ្ទុកបញ្ជីដឹកជញ្ជូនបានទេ (${res.statusCode})');
    }
    final data = json.decode(res.body) as List<dynamic>;
    return data.map((p) {
      final customer = p['customerId'];
      final name = customer is Map
          ? (customer['name'] ?? 'អតិថិជន')
          : 'អតិថិជន';
      return Conversation(
        packageId: (p['_id'] ?? '').toString(),
        trackingNumber: (p['trackingNumber'] ?? '').toString(),
        status: (p['status'] ?? '').toString(),
        peerName: name.toString(),
      );
    }).toList();
  }
}
