import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ជញ្ជូន',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C5F8A)),
      ),
      // ── Router wiring ────────────────────────────────────────────────────
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}