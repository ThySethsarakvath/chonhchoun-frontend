import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/branch_wallet_models.dart';

class BranchWalletService {
  String get _baseApi => '$baseUrl/branch-wallet';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<BranchWalletView> getMyWallet() async {
    final res = await http.get(
      Uri.parse('$_baseApi/me'),
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return BranchWalletView.fromJson(body);
    }

    throw ApiException(_messageFromBody(body, 'Failed to load wallet'), res.statusCode);
  }

  Future<BranchWalletSummary> getMyWalletSummary() async {
    final res = await http.get(
      Uri.parse('$_baseApi/me/summary'),
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return BranchWalletSummary.fromJson(body);
    }

    throw ApiException(
      _messageFromBody(body, 'Failed to load wallet summary'),
      res.statusCode,
    );
  }

  Future<List<BranchWalletTransaction>> getMyTransactions({
    String? dateFrom,
    String? dateTo,
  }) async {
    final uri = Uri.parse('$_baseApi/me/transactions').replace(
      queryParameters: {
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      },
    );
    final res = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body is List) {
      return body
          .map((item) => BranchWalletTransaction.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to load wallet transactions', res.statusCode);
  }

  String _messageFromBody(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is List) return message.join(', ');
    return message as String? ?? fallback;
  }
}
