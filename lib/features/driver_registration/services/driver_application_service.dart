import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../../../global/base_url.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/driver_application_model.dart';

class DriverApplicationService {
  String get _url => baseUrl;

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
    required File avatarFile,
    required File cvFile,
    required File nationalIdFile,
    required File drivingLicenseFile,
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

    final body = json.decode(response.body) as Map<String, dynamic>;
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
    final body = json.decode(response.body);
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
    final body = json.decode(response.body);
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

  Future<void> approveApplication(String applicationId) async {
    final response = await http.post(
      Uri.parse('$_url/driver-applications/$applicationId/approve'),
      headers: await _authHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    throw ApiException(
      body['message'] as String? ??
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

    final body = json.decode(response.body) as Map<String, dynamic>;
    throw ApiException(
      body['message'] as String? ??
          'Failed to reject application (${response.statusCode})',
      response.statusCode,
    );
  }
}
