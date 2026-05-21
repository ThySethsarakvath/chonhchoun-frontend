import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart'; // Reusing ApiException
import '../../auth/tokens/token_storage.dart'; //
import '../models/branch_model.dart';

class BranchService {
  String get _adminUrl => '$baseUrl/admin/branches';
  String get _mapUrl => '$baseUrl/branches/map';

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
}
