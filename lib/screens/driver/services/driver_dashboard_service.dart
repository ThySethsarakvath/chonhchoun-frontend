import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../models/driver_earnings.dart';
import '../models/driver_package.dart';
import '../models/driver_route.dart';

class DriverDashboardService {
  String get _url => baseUrl;

  Future<List<DriverPackage>> fetchAssignedPackages(String accessToken) async {
    final res = await http.get(
      Uri.parse('$_url/packages/assigned'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      final list = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> ? decoded['data'] ?? [] : []);
      return (list as List<dynamic>)
          .map((e) => DriverPackage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load deliveries (${res.statusCode})');
  }

  Future<DriverEarningsSummary> fetchEarnings(String accessToken) async {
    final res = await http.get(
      Uri.parse('$_url/drivers/me/earnings'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return DriverEarningsSummary.fromJson(body);
    }
    throw Exception(
      body['message']?.toString() ??
          'Failed to load earnings (${res.statusCode})',
    );
  }

  Future<DriverRoutePlan?> fetchRoute(String accessToken) async {
    final res = await http.get(
      Uri.parse('$_url/drivers/me/route'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      if (body['hasRoute'] != true) return null;
      return DriverRoutePlan.fromJson(body);
    }
    throw Exception(
      body['message']?.toString() ??
          'Failed to load route (${res.statusCode})',
    );
  }
}
