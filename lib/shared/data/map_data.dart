import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static String get maptilerKey => dotenv.env['MAPTILER_KEY']?.trim() ?? '';

  static String get urlTemplate {
    if (maptilerKey.isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png'
        '?key=$maptilerKey';
  }

  static String get attributionLabel => maptilerKey.isEmpty
      ? '© OpenStreetMap contributors'
      : '© MapTiler © OpenStreetMap contributors';

  static const String userAgent = 'com.chonhchoun.app';
  static const LatLng driverMapCenter = LatLng(11.5564, 104.9282);
}
