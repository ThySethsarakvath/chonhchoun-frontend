import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/base_url.dart';

class DriverService {
  String get _url => baseUrl;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<dynamic>> fetchAvailablePackages(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_url/packages/available'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return json.decode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchDriverPackages(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_url/packages/driver/my'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            json.decode(res.body) as Map<String, dynamic>;
        return body['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> acceptPackage(
    String packageId,
    String token,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse('$_url/packages/$packageId/accept'),
        headers: _headers(token),
      );
      final body = json.decode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body is Map<String, dynamic>) {
        return body;
      }
      throw DriverApiException(_message(body, 'Unable to accept delivery.'));
    } on DriverApiException {
      rethrow;
    } catch (error) {
      throw DriverApiException('Unable to accept delivery: $error');
    }
  }

  Future<Map<String, dynamic>> syncPackage(
    String packageId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_url/packages/$packageId/simulation/sync'),
      headers: _headers(token),
    );
    final body = json.decode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body is Map<String, dynamic>) {
      return body;
    }
    throw DriverApiException(_message(body, 'Unable to update delivery.'));
  }

  Future<Map<String, dynamic>> verifyDeliveryQr({
    required String packageId,
    required String purpose,
    required String verificationToken,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/packages/$packageId/verify'),
      headers: _headers(token),
      body: json.encode({'purpose': purpose, 'token': verificationToken}),
    );
    final body = json.decode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body is Map<String, dynamic>) {
      return body;
    }
    throw DriverApiException(
      _message(body, 'Unable to verify the delivery QR code.'),
    );
  }

  Future<bool> updatePackageStatus(
    String packageId,
    String status,
    String token,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse('$_url/packages/$packageId/status'),
        headers: _headers(token),
        body: json.encode({'status': status}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> updateDriverStatus(
    bool isOnline,
    String token,
  ) async {
    try {
      final payload = <String, dynamic>{'isOnline': isOnline};

      final res = await http.patch(
        Uri.parse('$_url/users/me/driver-status'),
        headers: _headers(token),
        body: json.encode(payload),
      );
      final body = json.decode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body is Map<String, dynamic>) {
        return body;
      }
      throw DriverApiException(
        _message(body, 'Unable to update driver status.'),
      );
    } on DriverApiException {
      rethrow;
    } catch (error) {
      throw DriverApiException('Unable to update driver status: $error');
    }
  }

  String _message(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      final value = body['message'];
      if (value is List) return value.join(', ');
      if (value is String && value.isNotEmpty) return value;
    }
    return fallback;
  }
}

class DriverApiException implements Exception {
  const DriverApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
