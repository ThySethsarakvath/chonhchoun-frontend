import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/revenue_sharing_model.dart';

class RevenueSharingUpdateRequest {
  final int senderBranchPercent;
  final int receiverBranchPercent;
  final int companyPercent;
  final String? note;

  const RevenueSharingUpdateRequest({
    required this.senderBranchPercent,
    required this.receiverBranchPercent,
    required this.companyPercent,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'senderBranchPercent': senderBranchPercent,
        'receiverBranchPercent': receiverBranchPercent,
        'companyPercent': companyPercent,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

class RevenueSharingService {
  String get _url => '$baseUrl/admin/revenue-sharing';

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<RevenueSharingConfig> getCurrentConfig() async {
    final res = await http.get(
      Uri.parse('$_url/current'),
      headers: await _headers(),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return RevenueSharingConfig.fromJson(body);
    }
    throw ApiException(
      body['message'] as String? ?? 'Failed to fetch revenue sharing rule',
      res.statusCode,
    );
  }

  Future<List<RevenueSharingConfig>> getHistory() async {
    final res = await http.get(
      Uri.parse('$_url/history'),
      headers: await _headers(),
    );
    final body = json.decode(res.body) as List<dynamic>;
    if (res.statusCode == 200) {
      return body
          .map((item) => RevenueSharingConfig.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Failed to fetch revenue sharing history', res.statusCode);
  }

  Future<RevenueSharingConfig> createVersion(
    RevenueSharingUpdateRequest request,
  ) async {
    final res = await http.post(
      Uri.parse(_url),
      headers: await _headers(),
      body: json.encode(request.toJson()),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201 || res.statusCode == 200) {
      return RevenueSharingConfig.fromJson(body);
    }
    throw ApiException(
      body['message'] as String? ?? 'Failed to update revenue sharing rule',
      res.statusCode,
    );
  }
}
