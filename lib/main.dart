import 'package:flutter/material.dart';

import 'screens/agency/driver_map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chonh Choun',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DriverMapScreen(), // 👈 TEMP TEST
      debugShowCheckedModeBanner: false,
    );
  }
}