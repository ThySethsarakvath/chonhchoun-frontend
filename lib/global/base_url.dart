import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get mapTilerKey {
  final key = dotenv.env['MAPTILER_KEY']?.trim();
  if (key == null || key.isEmpty) {
    throw StateError('MAPTILER_KEY is missing from .env');
  }
  return key;
}

String get baseUrl {
  if (kIsWeb) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  if (Platform.isAndroid) {
    return dotenv.env['API_URL_ANDROID_EMU']!;
  }

  return dotenv.env['API_URL_LOCAL']!;
}
