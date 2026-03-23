import 'package:flutter/material.dart';
import 'package:frontend/screens/generals/landing_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C5F8A)),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}