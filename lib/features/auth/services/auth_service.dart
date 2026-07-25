import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../../../global/base_url.dart';
import '../tokens/token_storage.dart';

/// Wraps a server error message extracted from the response body.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class AuthService {
  String get _url => baseUrl;

  static const _headers = {'Content-Type': 'application/json'};

  String _khmerError(String? message, int statusCode) {
    final normalized = (message ?? '').toLowerCase();
    if (normalized.contains('invalid credential') ||
        normalized.contains('incorrect password') ||
        normalized.contains('wrong password')) {
      return 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ។';
    }
    if (normalized.contains('already exists') ||
        normalized.contains('already registered') ||
        normalized.contains('email taken')) {
      return 'អ៊ីមែលនេះត្រូវបានប្រើរួចហើយ។';
    }
    if (normalized.contains('not found')) {
      return 'រកមិនឃើញគណនីនេះទេ។';
    }
    if (normalized.contains('otp') &&
        (normalized.contains('invalid') || normalized.contains('incorrect'))) {
      return 'លេខកូដផ្ទៀងផ្ទាត់មិនត្រឹមត្រូវ។';
    }
    if (normalized.contains('expired')) {
      return 'លេខកូដ ឬសំណើនេះបានផុតកំណត់។ សូមព្យាយាមម្ដងទៀត។';
    }
    if (statusCode == 429 || normalized.contains('too many')) {
      return 'អ្នកបានព្យាយាមច្រើនដងពេក។ សូមរង់ចាំបន្តិច។';
    }
    if (statusCode >= 500) {
      return 'ម៉ាស៊ីនបម្រើមានបញ្ហា។ សូមព្យាយាមម្ដងទៀតនៅពេលក្រោយ។';
    }
    return 'សំណើមិនបានជោគជ័យ។ សូមពិនិត្យព័ត៌មាន និងព្យាយាមម្ដងទៀត។';
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response res) {
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['message'] as String? ?? body['error'] as String?;
    throw ApiException(_khmerError(msg, res.statusCode), res.statusCode);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$_url$path'),
      headers: _headers,
      body: json.encode(payload),
    );
    return _decode(res);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// POST /auth/login → { accessToken, refreshToken }
  Future<AuthTokens> login(LoginRequest req) async {
    final data = await _post('/auth/login', req.toJson());
    final tokens = AuthTokens.fromJson(data);
    // Save tokens to local storage
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  // ── Registration ─────────────────────────────────────────────────────────

  /// POST /auth/driver-register → { accessToken, refreshToken } (Bypass OTP)
  Future<AuthTokens> driverRegister(Map<String, dynamic> payload) async {
    final data = await _post('/auth/driver-register', payload);
    final tokens = AuthTokens.fromJson(data);
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  /// POST /auth/register/initiate → sends OTP, returns { message }
  Future<void> initiateRegister(InitiateRegisterRequest req) async {
    await _post('/auth/register/initiate', req.toJson());
  }

  /// POST /auth/register/verify-email → { setupToken }
  Future<SetupTokenResponse> verifyEmail(VerifyEmailRequest req) async {
    final data = await _post('/auth/register/verify-email', req.toJson());
    return SetupTokenResponse.fromJson(data);
  }

  /// POST /auth/register/complete → { accessToken, refreshToken }
  Future<AuthTokens> completeRegister(CompleteRegisterRequest req) async {
    final data = await _post('/auth/register/complete', req.toJson());
    final tokens = AuthTokens.fromJson(data);
    // Save tokens to local storage
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  // ── Password reset ────────────────────────────────────────────────────────

  /// POST /auth/password/forgot → sends OTP, returns { message }
  Future<void> forgotPassword(ForgotPasswordRequest req) async {
    await _post('/auth/password/forgot', req.toJson());
  }

  /// POST /auth/password/verify-otp → { resetToken }
  Future<ResetTokenResponse> verifyOtp(VerifyOtpRequest req) async {
    final data = await _post('/auth/password/verify-otp', req.toJson());
    return ResetTokenResponse.fromJson(data);
  }

  /// POST /auth/password/reset → { message }
  Future<void> resetPassword(ResetPasswordRequest req) async {
    await _post('/auth/password/reset', req.toJson());
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// POST /auth/logout → clears session on backend
  Future<void> logout({required String accessToken}) async {
    final res = await http.post(
      Uri.parse('$_url/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final msg = body['message'] as String? ?? body['error'] as String?;
      throw ApiException(_khmerError(msg, res.statusCode), res.statusCode);
    }
  }
}
