import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_api_base_url.dart';

class ApiClient {
  const ApiClient();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('$appApiBaseUrl$path');

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }

      throw ApiException(
        'Something went wrong (${response.statusCode})',
        response.statusCode,
      );
    }

    final decoded = json.decode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'message': decoded.toString()};

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
      _uri(path),
      headers: _headers,
      body: json.encode(payload),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? bearerToken,
  }) async {
    final response = await http.get(
      _uri(path),
      headers: _buildHeaders(bearerToken: bearerToken),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    required String fileField,
    required File file,
    String? bearerToken,
  }) async {
    final request = http.MultipartRequest('PATCH', _uri(path))
      ..headers.addAll(_buildHeaders(bearerToken: bearerToken, json: false))
      ..files.add(await http.MultipartFile.fromPath(fileField, file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }

  Map<String, String> _buildHeaders({
    String? bearerToken,
    bool json = true,
  }) {
    final headers = <String, String>{};
    if (json) {
      headers.addAll(_headers);
    }
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }
    return headers;
  }
}
