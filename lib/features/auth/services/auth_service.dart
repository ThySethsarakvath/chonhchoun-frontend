import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/auth_models.dart';
import 'auth_session_service.dart';

export '../../../core/network/api_exception.dart';

class AuthService {
  AuthService({ApiClient? client, AuthSessionService? sessionService})
      : _client = client ?? const ApiClient(),
        _sessionService = sessionService ?? AuthSessionService();

  final ApiClient _client;
  final AuthSessionService _sessionService;

  Future<AuthTokens> login(LoginRequest req) async {
    final data = await _client.post('/auth/login', req.toJson());
    final tokens = AuthTokens.fromJson(data);
    await _sessionService.saveSession(tokens);
    return tokens;
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
    final tokens = AuthTokens.fromJson(data);
    await _sessionService.saveSession(tokens);
    return tokens;
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
