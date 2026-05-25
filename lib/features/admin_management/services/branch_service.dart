import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart'; // Reusing ApiException
import '../../auth/tokens/token_storage.dart'; //
import '../models/branch_model.dart';

class BranchService {
  String get _adminUrl => '$baseUrl/admin/branches';
  String get _mapUrl => '$baseUrl/branches/map';
  String get _myBranchUrl => '$baseUrl/branches/me';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Branch>> getAllBranches() async {
    final res = await http.get(
      Uri.parse(_adminUrl),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((json) => Branch.fromJson(json)).toList();
    }
    throw ApiException('Failed to fetch branches', res.statusCode);
  }

  Future<List<Branch>> getMapBranches() async {
    final res = await http.get(Uri.parse(_mapUrl));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data
          .map((json) => Branch.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to fetch branch map data', res.statusCode);
  }

  Future<Branch> getMyBranch() async {
    final res = await http.get(
      Uri.parse(_myBranchUrl),
      headers: await _getHeaders(),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return Branch.fromJson(body);
    }

    throw ApiException(
      body['message'] as String? ?? 'Failed to fetch your branch information',
      res.statusCode,
    );
  }

  Future<Branch> updateBranch({
    required String branchId,
    required String name,
    required String address,
    required String phone,
    String? description,
    required double latitude,
    required double longitude,
  }) async {
    final res = await http.patch(
      Uri.parse('$_adminUrl/$branchId'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'address': address,
        'phone': phone,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return Branch.fromJson(body);
    }

    final message = body['message'];

    throw ApiException(
      message is List
          ? message.join(', ')
          : message as String? ?? 'Failed to update branch',
      res.statusCode,
    );
  }
}
