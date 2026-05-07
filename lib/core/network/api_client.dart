import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_api_base_url.dart';

class ApiClient {
  const ApiClient();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final body = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Something went wrong (${response.statusCode})';

    throw ApiException(message, response.statusCode);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$appApiBaseUrl$path'),
      headers: _headers,
      body: json.encode(payload),
    );

    return _decode(response);
  }
}
