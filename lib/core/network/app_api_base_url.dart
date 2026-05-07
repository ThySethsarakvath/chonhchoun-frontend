import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get appApiBaseUrl {
  if (kIsWeb) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  if (Platform.isIOS) {
    return dotenv.env['API_URL_LOCAL']!;
  }

  if (Platform.isAndroid) {
    return dotenv.env['API_URL_ANDROID_EMU']!;
  }

  return dotenv.env['API_URL_LOCAL']!;
}
