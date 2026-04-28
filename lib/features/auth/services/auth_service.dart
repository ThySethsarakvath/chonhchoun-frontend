import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

/// Wraps a server error message extracted from the response body.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class AuthService {
  static const String _base = 'http://192.168.204.194:3000/api/v1';

  static const _headers = {'Content-Type': 'application/json'};

  // ── helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response res) {
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['message'] as String? ??
        body['error'] as String? ??
        'Something went wrong (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: json.encode(payload),
    );
    return _decode(res);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// POST /auth/login → { accessToken, refreshToken }
  Future<AuthTokens> login(LoginRequest req) async {
    final data = await _post('/auth/login', req.toJson());
    return AuthTokens.fromJson(data);
  }

  // ── Registration ─────────────────────────────────────────────────────────

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
    return AuthTokens.fromJson(data);
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
}