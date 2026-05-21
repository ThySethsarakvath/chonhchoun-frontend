import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/admin_activity_model.dart';
import '../models/admin_user_model.dart';

class UpgradeBranchOwnerRequest {
  final String phone;
  final String address;
  final double latitude;
  final double longitude;

  const UpgradeBranchOwnerRequest({
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class AdminUserService {
  String get _url => '$baseUrl/admin/users';

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AdminUser>> getUsers() async {
    final res = await http.get(Uri.parse(_url), headers: await _headers());
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List<dynamic>;
      return data
          .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(
      body['message'] as String? ?? 'Failed to fetch users',
      res.statusCode,
    );
  }

  Future<List<AdminActivity>> getActivityHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/activity-history'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List<dynamic>;
      return data
          .map((item) => AdminActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    throw ApiException(
      body['message'] as String? ?? 'Failed to fetch activity history',
      res.statusCode,
    );
  }

  Future<Map<String, dynamic>> upgradeToBranchOwner({
    required String userId,
    required UpgradeBranchOwnerRequest request,
  }) async {
    final res = await http.patch(
      Uri.parse('$_url/$userId/upgrade-branch-owner'),
      headers: await _headers(),
      body: json.encode(request.toJson()),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return body;
    }

    throw ApiException(
      body['message'] as String? ?? 'Failed to upgrade user',
      res.statusCode,
    );
  }

  Future<Map<String, dynamic>> downgradeBranchOwner({
    required String userId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_url/$userId/downgrade-branch-owner'),
      headers: await _headers(),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return body;
    }

    throw ApiException(
      body['message'] as String? ?? 'Failed to downgrade user',
      res.statusCode,
    );
  }
}
