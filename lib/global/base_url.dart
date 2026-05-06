import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl {
  // 1. Web
  if (kIsWeb) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  // 2. iOS Simulator
  if (Platform.isIOS) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  // 3. Android
  if (Platform.isAndroid) {
    return dotenv.env['API_URL_ANDROID_EMU']!;
  }

  return dotenv.env['API_URL_LOCAL']!;
}