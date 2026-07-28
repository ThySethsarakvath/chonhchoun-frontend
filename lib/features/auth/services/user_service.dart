import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import '../../../global/base_url.dart';
import '../models/user_model.dart';
class UserService {
  String get _url => baseUrl;

  Future<UserProfile> updateProfile({
    required String accessToken,
    required String name,
    required String phone,
  }) async {
    final uri = Uri.parse('$_url/users/me');
    final res = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'phone': phone,
      }),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return UserProfile.fromJson(body);
    }

    final message = body['message'];
    throw Exception(
      message is List
          ? message.join(', ')
          : message as String? ??
              body['error'] as String? ??
              'Failed to update profile (${res.statusCode})',
    );
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required File imageFile,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_url/users/me/avatar');
    final extensionName = extension(imageFile.path).toLowerCase().replaceAll('.', '');
    final mimeSubtype = extensionName == 'jpg' ? 'jpeg' : extensionName;
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path, contentType: MediaType('image', mimeSubtype)));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    final msg = body['message'] as String? ??
        body['error'] as String? ??
        'Avatar upload failed (${response.statusCode})';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> uploadAvatarBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_url/users/me/avatar');
    final extensionName = extension(fileName).toLowerCase().replaceAll('.', '');
    final mimeSubtype = extensionName == 'png'
        ? 'png'
        : extensionName == 'webp'
        ? 'webp'
        : 'jpeg';
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    final message = body['message'];
    throw Exception(
      message is List
          ? message.join(', ')
          : message as String? ??
              body['error'] as String? ??
              'Avatar upload failed (${response.statusCode})',
    );
  }

  Future<UserProfile> getMe({required String accessToken}) async {
    final uri = Uri.parse('$_url/users/me');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return UserProfile.fromJson(body);
    }
    final msg = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch user profile (${res.statusCode})';
    throw Exception(msg);
  }

  Future<DriverStateSnapshot> getDriverState({required String accessToken}) async {
    final uri = Uri.parse('$_url/users/me/driver-state');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return DriverStateSnapshot.fromJson(body);
    }
    final msg = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to fetch driver state (${res.statusCode})';
    throw Exception(msg);
  }

  Future<UserProfile> updateDriverAvailabilityStatus({
    required String accessToken,
    required String availabilityStatus,
  }) async {
    final uri = Uri.parse('$_url/users/me/availability-status');
    final res = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'availabilityStatus': availabilityStatus,
      }),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return UserProfile.fromJson(body);
    }
    final msg = body['message'] as String? ??
        body['error'] as String? ??
        'Failed to update driver availability (${res.statusCode})';
    throw Exception(msg);
  }
}
