import 'package:flutter/material.dart';
import '../../router/app_router.dart';
import '../../pages/onboarding_page.dart';

/// Thin screen wrapper so the router can reference a named screen class,
/// while the real UI logic stays inside the feature folder.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      onFinished: () {
        // When the user finishes or skips onboarding → go to login.
        // Change AppRoutes.login to whatever your next screen is.
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      },
    );
  }
}