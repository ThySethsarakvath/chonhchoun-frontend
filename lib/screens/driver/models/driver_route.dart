import 'package:latlong2/latlong.dart';

class DriverRouteStop {
  const DriverRouteStop({
    required this.order,
    required this.branchName,
    required this.point,
    required this.etaSeconds,
    required this.packageCount,
  });

  final int order;
  final String branchName;
  final LatLng? point;
  final int etaSeconds;
  final int packageCount;

  factory DriverRouteStop.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    return DriverRouteStop(
      order: (json['order'] as num?)?.toInt() ?? 0,
      branchName: (json['branchName'] ?? 'Stop').toString(),
      point: (lat != null && lng != null) ? LatLng(lat, lng) : null,
      etaSeconds: (json['etaSeconds'] as num?)?.toInt() ?? 0,
      packageCount: (json['packageCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverRouteSource {
  const DriverRouteSource({required this.branchName, required this.point});

  final String branchName;
  final LatLng point;
}

class DriverRoutePlan {
  const DriverRoutePlan({
    required this.isSample,
    required this.status,
    required this.isCompleted,
    required this.totalDurationSeconds,
    required this.totalPackages,
    required this.totalStops,
    required this.source,
    required this.stops,
    required this.geometry,
  });

  final bool isSample;
  final String status;
  final bool isCompleted;
  final int totalDurationSeconds;
  final int totalPackages;
  final int totalStops;
  final DriverRouteSource? source;
  final List<DriverRouteStop> stops;
  final List<LatLng> geometry;

  String get durationLabel {
    final minutes = (totalDurationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  factory DriverRoutePlan.fromJson(Map<String, dynamic> json) {
    final src = json['source'] as Map<String, dynamic>?;
    final srcLat = (src?['lat'] as num?)?.toDouble();
    final srcLng = (src?['lng'] as num?)?.toDouble();
    return DriverRoutePlan(
      isSample: json['isSample'] == true,
      status: (json['status'] ?? 'PLANNED').toString(),
      isCompleted: json['isCompleted'] == true,
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      totalPackages: (json['totalPackages'] as num?)?.toInt() ?? 0,
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      source: (src != null && srcLat != null && srcLng != null)
          ? DriverRouteSource(
              branchName: (src['branchName'] ?? 'Origin').toString(),
              point: LatLng(srcLat, srcLng),
            )
          : null,
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((e) => DriverRouteStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      geometry: (json['geometry'] as List<dynamic>? ?? [])
          .whereType<List<dynamic>>()
          .where((p) => p.length >= 2)
          .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList(),
    );
  }
}
