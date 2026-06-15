import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/driver_application_model.dart';
import '../models/driver_management_model.dart';

class DriverApplicationService {
  String get _url => baseUrl;

  dynamic _safeDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  MediaType _mediaTypeForFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<void> submitApplication({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String branchId,
    String? vehicleType,
    String? plateNumber,
    required File avatarFile,
    required File cvFile,
    required File nationalIdFile,
    File? drivingLicenseFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_url/driver-applications'),
    )
      ..fields.addAll({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
        'branchId': branchId,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (plateNumber != null && plateNumber.trim().isNotEmpty)
          'plateNumber': plateNumber.trim(),
      })
      ..files.addAll([
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: _mediaTypeForFile(avatarFile),
        ),
        await http.MultipartFile.fromPath(
          'cv',
          cvFile.path,
          contentType: _mediaTypeForFile(cvFile),
        ),
        await http.MultipartFile.fromPath(
          'nationalId',
          nationalIdFile.path,
          contentType: _mediaTypeForFile(nationalIdFile),
        ),
        if (drivingLicenseFile != null)
          await http.MultipartFile.fromPath(
            'drivingLicense',
            drivingLicenseFile.path,
            contentType: _mediaTypeForFile(drivingLicenseFile),
          ),
      ]);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    final message = body['message'];
    throw ApiException(
      message is List
          ? message.join(', ')
          : message as String? ??
              body['error'] as String? ??
              'Driver application submission failed (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<DriverApplication>> getBranchOwnerApplications() async {
    final response = await http.get(
      Uri.parse('$_url/driver-applications/branch-owner'),
      headers: await _authHeaders(),
    );
    final body = _safeDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map(
            (item) => DriverApplication.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw ApiException(
      message as String? ??
          'Failed to load branch driver applications (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<List<BranchDriver>> getBranchDrivers() async {
    final response = await http.get(
      Uri.parse('$_url/driver-applications/branch-owner/drivers'),
      headers: await _authHeaders(),
    );
    final body = _safeDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((item) => BranchDriver.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw ApiException(
      message as String? ??
          'Failed to load branch drivers (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> approveApplication(
    String applicationId, {
    String? vehicleType,
    String? assignedVehicleCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/$applicationId/approve'),
      headers: await _authHeaders(),
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

  Future<void> rejectApplication(
    String applicationId, {
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/$applicationId/reject'),
      headers: await _authHeaders(),
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

  Future<void> updateBranchDriverVehicleType(
    String driverId, {
    required String vehicleType,
    String? assignedVehicleCode,
  }) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/branch-owner/drivers/$driverId/vehicle-type'),
      headers: await _authHeaders(),
      body: json.encode({
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
          'Failed to update driver vehicle type (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<BranchDriverManagementOverview> getBranchOwnerManagementOverview() async {
    final response = await http.get(
      Uri.parse('$_url/driver-applications/branch-owner/management-overview'),
      headers: await _authHeaders(),
    );
    final body =
        _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    if (response.statusCode == 200) {
      return BranchDriverManagementOverview.fromJson(body);
    }

    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to load driver management overview (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> createBranchVehicle({
    required String code,
    required String vehicleType,
    String? plateNumber,
    String? currentWarehouse,
    double? maxWeightKg,
    double? maxVolumeM3,
    int? maxPackageCount,
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/branch-owner/vehicles'),
      headers: await _authHeaders(),
      body: json.encode({
        'code': code,
        'type': vehicleType,
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

  Future<void> updateBranchVehicle(
    String vehicleId, {
    String? plateNumber,
    String? currentWarehouse,
    String? status,
    double? maxWeightKg,
    int? maxPackageCount,
  }) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/branch-owner/vehicles/$vehicleId'),
      headers: await _authHeaders(),
      body: json.encode({
        'plateNumber': plateNumber,
        'maxWeightKg': maxWeightKg,
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

  Future<void> deactivateBranchVehicle(String vehicleId) async {
    final response = await http.patch(
      Uri.parse(
        '$_url/driver-applications/branch-owner/vehicles/$vehicleId/deactivate',
      ),
      headers: await _authHeaders(),
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

  Future<void> activateBranchVehicle(String vehicleId) async {
    final response = await http.patch(
      Uri.parse(
        '$_url/driver-applications/branch-owner/vehicles/$vehicleId/activate',
      ),
      headers: await _authHeaders(),
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

  Future<void> updateBranchDriverManagement(
    String driverId, {
    required String availabilityStatus,
    String? licenseNumber,
    double? maxLoadWeightKg,
    int? maxPackageCount,
  }) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/branch-owner/drivers/$driverId/management'),
      headers: await _authHeaders(),
      body: json.encode({
        'availabilityStatus': availabilityStatus,
        if (licenseNumber != null && licenseNumber.trim().isNotEmpty)
          'licenseNumber': licenseNumber.trim(),
        if (maxLoadWeightKg != null) 'maxLoadWeightKg': maxLoadWeightKg,
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
          'Failed to update driver management (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> assignVehicleToDriver(
    String driverId, {
    required String vehicleId,
    String assignmentType = 'PRIMARY',
  }) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/branch-owner/drivers/$driverId/assign-vehicle'),
      headers: await _authHeaders(),
      body: json.encode({
        'vehicleId': vehicleId,
        'assignmentType': assignmentType,
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
          'Failed to assign vehicle (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> unassignVehicleFromDriver(String driverId) async {
    final response = await http.patch(
      Uri.parse(
        '$_url/driver-applications/branch-owner/drivers/$driverId/unassign-vehicle',
      ),
      headers: await _authHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to unassign vehicle (${response.statusCode})',
      response.statusCode,
    );
  }

  Future<void> deactivateBranchDriver(String driverId) async {
    final response = await http.patch(
      Uri.parse('$_url/driver-applications/branch-owner/drivers/$driverId/deactivate'),
      headers: await _authHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _safeDecode(response.body) as Map<String, dynamic>? ?? const {};
    throw ApiException(
      (body['message'] is List
          ? (body['message'] as List).join(', ')
          : body['message'] as String?) ??
          'Failed to remove driver (${response.statusCode})',
      response.statusCode,
    );
  }
}
