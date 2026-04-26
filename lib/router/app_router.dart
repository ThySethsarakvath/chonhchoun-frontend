import 'package:flutter/material.dart';
import '../screens/generals/landing_page.dart';
import '../screens/generals/onboarding_screen.dart';
// import '../screens/generals/auth/login_screen.dart';
// import '../screens/generals/auth/register_screen.dart';
// import '../screens/customer/customer_workspace_screen.dart';
// import '../screens/driver/driver_workspace_screen.dart';

/// Central route name constants — use these everywhere instead of raw strings.
/// Example: Navigator.pushNamed(context, AppRoutes.onboarding)
abstract class AppRoutes {
  AppRoutes._();

  static const String landing    = '/';
  static const String onboarding = '/onboarding';
  static const String login      = '/login';
  static const String register   = '/register';
  // static const String customer   = '/customer';
  // static const String driver     = '/driver';
}

/// Route factory — all route definitions live here.
class AppRouter {
  AppRouter._();

  /// Pass this to [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.landing:
        return _fade(const LandingPage());

      case AppRoutes.onboarding:
        return _fade(const OnboardingScreen());

      // ── Stub routes — replace body with real screens when ready ──────────
      case AppRoutes.login:
        return _fade(_stub('Login Screen'));

      case AppRoutes.register:
        return _fade(_stub('Register Screen'));

      // case AppRoutes.customer:
      //   return _fade(_stub('Customer Workspace'));

      // case AppRoutes.driver:
      //   return _fade(_stub('Driver Workspace'));

      default:
        return _fade(_stub('404 — Page not found'));
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Smooth fade transition (works well after splash/onboarding).
  static PageRouteBuilder<dynamic> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Placeholder widget for screens not yet built.
  static Widget _stub(String name) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(child: Text(name, style: const TextStyle(fontSize: 18))),
    );
  }
}