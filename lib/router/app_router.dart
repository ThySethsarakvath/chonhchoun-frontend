import 'package:flutter/material.dart';

// ── Screens ───────────────────────────────────────────────────────────────────
import '../screens/generals/landing_page.dart';
import '../screens/generals/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/validate_email_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/set_password_screen.dart';
// import '../screens/customer/customer_workspace_screen.dart';
// import '../screens/driver/driver_workspace_screen.dart';

// ── Route name constants ──────────────────────────────────────────────────────

abstract class AppRoutes {
  AppRoutes._();

  static const String landing       = '/';
  static const String onboarding    = '/onboarding';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String validateEmail = '/validate-email';
  static const String otp           = '/otp';
  static const String setPassword   = '/set-password';
  static const String customer      = '/customer';
  static const String driver        = '/driver';
}

// ── Typed route arguments ─────────────────────────────────────────────────────

enum AuthFlow { register, forgotPassword }

class ValidateEmailArgs {
  final AuthFlow flow;
  final String? email;
  final String? name;
  const ValidateEmailArgs({required this.flow, this.email, this.name});
}

class OtpArgs {
  final AuthFlow flow;
  final String email;
  final String? name;
  const OtpArgs({required this.flow, required this.email, this.name});
}

class SetPasswordArgs {
  final AuthFlow flow;
  final String? setupToken;
  final String? resetToken;
  const SetPasswordArgs({required this.flow, this.setupToken, this.resetToken});
}

// ── Route factory ─────────────────────────────────────────────────────────────

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.landing:
        return _fade(const LandingPage());
      case AppRoutes.onboarding:
        return _fade(const OnboardingScreen());
      case AppRoutes.login:
        return _slide(const LoginScreen());
      case AppRoutes.register:
        return _slide(const RegisterScreen());
      case AppRoutes.validateEmail:
        final args = settings.arguments as ValidateEmailArgs;
        return _slide(ValidateEmailScreen(args: args));
      case AppRoutes.otp:
        final args = settings.arguments as OtpArgs;
        return _slide(OtpScreen(args: args));
      case AppRoutes.setPassword:
        final args = settings.arguments as SetPasswordArgs;
        return _slide(SetPasswordScreen(args: args));
      case AppRoutes.customer:
        return _fade(_stub('Customer Workspace'));
      case AppRoutes.driver:
        return _fade(_stub('Driver Workspace'));
      default:
        return _fade(_stub('404 — Page not found'));
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static PageRouteBuilder<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Widget _stub(String name) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(child: Text(name, style: const TextStyle(fontSize: 18))),
      );
}