import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/auth_models.dart';

export '../../../core/network/api_exception.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  Future<AuthTokens> login(LoginRequest req) async {
    final data = await _client.post('/auth/login', req.toJson());
    return AuthTokens.fromJson(data);
  }

  Future<void> initiateRegister(InitiateRegisterRequest req) async {
    await _client.post('/auth/register/initiate', req.toJson());
  }

  Future<SetupTokenResponse> verifyEmail(VerifyEmailRequest req) async {
    final data = await _client.post('/auth/register/verify-email', req.toJson());
    return SetupTokenResponse.fromJson(data);
  }

  Future<AuthTokens> completeRegister(CompleteRegisterRequest req) async {
    final data = await _client.post('/auth/register/complete', req.toJson());
    return AuthTokens.fromJson(data);
  }

  Future<void> forgotPassword(ForgotPasswordRequest req) async {
    await _client.post('/auth/password/forgot', req.toJson());
  }

  Future<ResetTokenResponse> verifyOtp(VerifyOtpRequest req) async {
    final data = await _client.post('/auth/password/verify-otp', req.toJson());
    return ResetTokenResponse.fromJson(data);
  }

  Future<void> resetPassword(ResetPasswordRequest req) async {
    await _client.post('/auth/password/reset', req.toJson());
  }
}
