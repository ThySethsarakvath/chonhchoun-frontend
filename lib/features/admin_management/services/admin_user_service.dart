import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/admin_user_model.dart';

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
}
