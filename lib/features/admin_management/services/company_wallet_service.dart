import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/company_wallet_model.dart';

class CompanyWalletService {
  String get _baseApi => '$baseUrl/company-wallet';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<CompanyWalletSummary> getCompanyWalletSummary() async {
    final res = await http.get(
      Uri.parse('$_baseApi/summary'),
      headers: await _getHeaders(),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return CompanyWalletSummary.fromJson(body);
    }

    throw ApiException(
      _messageFromBody(body, 'Failed to load company wallet summary'),
      res.statusCode,
    );
  }

  Future<List<CompanyWalletTransaction>> getCompanyTransactions({
    String? dateFrom,
    String? dateTo,
  }) async {
    final uri = Uri.parse('$_baseApi/transactions').replace(
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
          .map(
            (item) => CompanyWalletTransaction.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw ApiException('Failed to load company wallet transactions', res.statusCode);
  }

  String _messageFromBody(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is List) return message.join(', ');
    return message as String? ?? fallback;
  }
}
