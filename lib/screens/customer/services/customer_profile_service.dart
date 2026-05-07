import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../features/auth/services/auth_session_service.dart';
import '../models/customer_profile.dart';

class CustomerProfileService {
  CustomerProfileService({
    ApiClient? client,
    AuthSessionService? sessionService,
  })  : _client = client ?? const ApiClient(),
        _sessionService = sessionService ?? AuthSessionService();

  final ApiClient _client;
  final AuthSessionService _sessionService;

  Future<CustomerProfile?> getCachedProfile() async {
    final user = await _sessionService.getCurrentUser();
    if (user == null) {
      return null;
    }

    return CustomerProfile.fromAuthUser(user);
  }

  Future<CustomerProfile> fetchProfile() async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please log in again to continue.', 401);
    }

    final data = await _client.get('/auth/me', bearerToken: token);
    final profile = CustomerProfile.fromJson(data);
    await _sessionService.updateUser(profile.toAuthUser());
    return profile;
  }

  Future<CustomerProfile> uploadAvatar(String filePath) async {
    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please log in again to continue.', 401);
    }

    final response = await _client.patchMultipart(
      '/users/me/avatar',
      fileField: 'file',
      file: File(filePath),
      bearerToken: token,
    );

    final profile = CustomerProfile.fromJson(
      response['user'] as Map<String, dynamic>,
    );
    await _sessionService.updateUser(profile.toAuthUser());
    return profile;
  }
}
