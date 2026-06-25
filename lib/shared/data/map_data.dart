import 'package:latlong2/latlong.dart';

class MapConfig {
  static const String maptilerKey = 'k0zSDACY9KkW3e9NetrQ';
  
  // Premium MapTiler Streets Skin
  static const String urlTemplate = 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey';
  
  static const String userAgent = 'com.chonhchoun.app';

  static const LatLng driverMapCenter = LatLng(11.5564, 104.9282); // Phnom Penh
}
