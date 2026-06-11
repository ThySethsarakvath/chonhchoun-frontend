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
      print("DEV-LOG: fetchAvailablePackages statusCode: ${res.statusCode}");
      print("DEV-LOG: fetchAvailablePackages body: ${res.body}");
      if (res.statusCode == 200) {
        return json.decode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("DEV-LOG: DriverService.fetchAvailablePackages exception: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchDriverPackages(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_url/packages/driver/my'),
        headers: _headers(token),
      );
      print("DEV-LOG: fetchDriverPackages statusCode: ${res.statusCode}");
      print("DEV-LOG: fetchDriverPackages body: ${res.body}");
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
        return body['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("DEV-LOG: DriverService.fetchDriverPackages exception: $e");
      return [];
    }
  }

  Future<bool> acceptPackage(String packageId, String token) async {
    try {
      final res = await http.patch(
        Uri.parse('$_url/packages/$packageId/accept'),
        headers: _headers(token),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePackageStatus(String packageId, String status, String token) async {
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

  Future<bool> updateDriverStatus(bool isOnline, Map<String, double>? location, String token) async {
    try {
      final payload = <String, dynamic>{
        'isOnline': isOnline,
      };
      if (location != null) {
        payload['currentLocation'] = location;
      }
      
      final res = await http.patch(
        Uri.parse('$_url/users/me/driver-status'),
        headers: _headers(token),
        body: json.encode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
