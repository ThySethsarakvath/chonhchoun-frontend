import 'package:latlong2/latlong.dart';

class Warehouse {
  final String name;
  final LatLng location;

  const Warehouse({
    required this.name,
    required this.location,
  });

  // Helper to create from JSON if needed later
  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }
}
