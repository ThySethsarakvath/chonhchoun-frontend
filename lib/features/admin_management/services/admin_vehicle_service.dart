import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../../driver_registration/models/driver_application_model.dart';
import '../../driver_registration/models/driver_management_model.dart';

class AdminVehicleService {
  String get _url => baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _safeDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  Future<List<DriverApplication>> getApplications() async {
    final response = await http.get(
      Uri.parse('$_url/driver-applications/admin/applications'),
      headers: await _headers(),
    );
    final body = _safeDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((item) => DriverApplication.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw ApiException(
      message as String? ??
          'Failed to load admin driver applications (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<List<ManagedVehicle>> getVehicles() async {
    final response = await http.get(
      Uri.parse('$_url/driver-applications/admin/vehicles'),
      headers: await _headers(),
    );
    final body = _safeDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((item) => ManagedVehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw ApiException(
      message as String? ??
          'Failed to load company vehicles (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> approveApplication(
    String applicationId, {
    String? vehicleType,
    String? assignedVehicleCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/admin/applications/$applicationId/approve'),
      headers: await _headers(),
      body: json.encode({
        if (vehicleType != null && vehicleType.isNotEmpty)
          'vehicleType': vehicleType,
        if (assignedVehicleCode != null && assignedVehicleCode.isNotEmpty)
          'assignedVehicleCode': assignedVehicleCode,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to approve application (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> rejectApplication(String applicationId, {String? reason}) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/admin/applications/$applicationId/reject'),
      headers: await _headers(),
      body: json.encode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to reject application (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> createVehicle({
    required String code,
    required String vehicleType,
    String? branchId,
    String? plateNumber,
    String? currentWarehouse,
    double? maxWeightKg,
    double? maxVolumeM3,
    int? maxPackageCount,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/admin/vehicles'),
      headers: await _headers(),
      body: json.encode({
        'code': code,
        'type': vehicleType,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (plateNumber != null && plateNumber.trim().isNotEmpty)
          'plateNumber': plateNumber.trim(),
        if (currentWarehouse != null && currentWarehouse.trim().isNotEmpty)
          'currentWarehouse': currentWarehouse.trim(),
        if (maxWeightKg != null) 'maxWeightKg': maxWeightKg,
        if (maxVolumeM3 != null) 'maxVolumeM3': maxVolumeM3,
        if (maxPackageCount != null) 'maxPackageCount': maxPackageCount,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to create vehicle (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> updateVehicle(
    String vehicleId, {
    String? branchId,
    String? plateNumber,
    String? currentWarehouse,
    String? status,
    double? maxWeightKg,
    double? maxVolumeM3,
    int? maxPackageCount,
  }) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/admin/vehicles/$vehicleId'),
      headers: await _headers(),
      body: json.encode({
        if (branchId != null) 'branchId': branchId,
        'plateNumber': plateNumber,
        'maxWeightKg': maxWeightKg,
        'maxVolumeM3': maxVolumeM3,
        'maxPackageCount': maxPackageCount,
        if (currentWarehouse != null) 'currentWarehouse': currentWarehouse,
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to update vehicle (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> activateVehicle(String vehicleId) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/admin/vehicles/$vehicleId/activate'),
      headers: await _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to activate vehicle (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> deactivateVehicle(String vehicleId) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/admin/vehicles/$vehicleId/deactivate'),
      headers: await _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to deactivate vehicle (${response.statusCode})',
      response.statusCode,
    );
  }
}
