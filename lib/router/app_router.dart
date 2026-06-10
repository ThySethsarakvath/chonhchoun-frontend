import 'package:flutter/material.dart';
import '../screens/landing_page.dart';
import '../screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/validate_email_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/set_password_screen.dart';
import '../features/home/pages/home_screen.dart';
import '../features/auth/models/user_model.dart';
import '../screens/customer/avatar_upload_screen.dart';
import '../screens/customer/setting_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../features/driver/screens/driver_home_screen.dart';

abstract class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String validateEmail = '/validate-email';
  static const String otp = '/otp';
  static const String setPassword = '/set-password';
  static const String avatarUpload = '/avatar-upload';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String customer = '/customer';
  static const String driver = '/driver';
}

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
  final String? userName;
  const SetPasswordArgs({
    required this.flow,
    this.setupToken,
    this.resetToken,
    this.userName,
  });
}

class AvatarUploadArgs {
  final String userName;
  final String accessToken;
  const AvatarUploadArgs({required this.userName, required this.accessToken});
}

enum ProfileSource { home, settings, drawer }

class ProfileArgs {
  final UserProfile? profile;
  final ProfileSource source;
  const ProfileArgs({this.profile, this.source = ProfileSource.home});
}

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
      case AppRoutes.avatarUpload:
        final args = settings.arguments as AvatarUploadArgs;
        return _slide(AvatarUploadScreen(args: args));
      case AppRoutes.profile:
        final args = settings.arguments as ProfileArgs?;
        return _fade(
          ProfileScreen(
            profile: args?.profile,
            source: args?.source ?? ProfileSource.home,
          ),
        );
      case AppRoutes.settings:
        return _fade(const SettingsScreen());
      case AppRoutes.customer:
        return _fade(const HomeScreen());
      case AppRoutes.driver:
        return _fade(const DriverHomeScreen());
      default:
        return _fade(_stub('404 — Page not found'));
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static PageRouteBuilder<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
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
