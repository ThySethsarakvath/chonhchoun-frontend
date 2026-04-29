import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl {
  // 1. Web
  if (kIsWeb) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  // 2. iOS Simulator
  // iOS Simulators can use localhost directly
  if (Platform.isIOS) {
    // Note: If testing on a PHYSICAL iPhone, you MUST use the Real Device IP
    // For simplicity, many devs just use the Real Device IP for all mobile testing
    return dotenv.env['API_URL_LOCAL']!;
  }

  // 3. Android
  if (Platform.isAndroid) {
    // If you are using a real Android phone (like your Oppo)
    // You would typically check if it's a physical device here.
    // For now, let's use the Real Device IP as the safest fallback.
    return dotenv.env['API_URL_REAL_DEVICE']!;
  }

  return dotenv.env['API_URL_LOCAL']!;
}