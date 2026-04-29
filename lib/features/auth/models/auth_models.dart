// ── Request models ────────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class InitiateRegisterRequest {
  final String name;
  final String email;

  InitiateRegisterRequest({required this.name, required this.email});

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}

class VerifyEmailRequest {
  final String email;
  final String otp;

  VerifyEmailRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class CompleteRegisterRequest {
  final String setupToken;
  final String password;
  final String confirmPassword;

  CompleteRegisterRequest({
    required this.setupToken,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'setupToken': setupToken,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class ResetPasswordRequest {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

// ── Response models ───────────────────────────────────────────────────────────

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

class SetupTokenResponse {
  final String setupToken;

  SetupTokenResponse({required this.setupToken});

  factory SetupTokenResponse.fromJson(Map<String, dynamic> json) =>
      SetupTokenResponse(setupToken: json['setupToken'] as String);
}

class ResetTokenResponse {
  final String resetToken;

  ResetTokenResponse({required this.resetToken});

  factory ResetTokenResponse.fromJson(Map<String, dynamic> json) =>
      ResetTokenResponse(resetToken: json['resetToken'] as String);
}