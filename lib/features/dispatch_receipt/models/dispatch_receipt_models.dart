import 'package:latlong2/latlong.dart';

import '../../admin_management/models/branch_model.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';

enum DispatchReceiptStatus { created, inTransit, completed, cancelled }

enum DispatchReceiptStopStatus { pending, arrived, confirmed, partial }

class DispatchReceiptUserRef {
  final String id;
  final String name;
  final String? phone;

  DispatchReceiptUserRef({required this.id, required this.name, this.phone});

  factory DispatchReceiptUserRef.fromJson(Map<String, dynamic> json) {
    return DispatchReceiptUserRef(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      phone: json['phone'] as String?,
    );
  }
}

class DispatchReceiptStop {
  final int stopOrder;
  final Branch destinationBranch;
  final List<BranchLogisticsShipment> shipments;
  final DispatchReceiptStopStatus status;
  final DateTime? arrivedAt;
  final int? estimatedArrivalSeconds;
  final double? routeProgress;
  final DateTime? confirmedAt;
  final DispatchReceiptUserRef? confirmedBy;
  final String? confirmationNotes;
  final List<BranchLogisticsShipment> missingShipments;
  final List<BranchLogisticsShipment> damagedShipments;

  DispatchReceiptStop({
    required this.stopOrder,
    required this.destinationBranch,
    required this.shipments,
    required this.status,
    this.arrivedAt,
    this.estimatedArrivalSeconds,
    this.routeProgress,
    this.confirmedAt,
    this.confirmedBy,
    this.confirmationNotes,
    this.missingShipments = const [],
    this.damagedShipments = const [],
  });

  factory DispatchReceiptStop.fromJson(Map<String, dynamic> json) {
    return DispatchReceiptStop(
      stopOrder: json['stopOrder'] as int,
      destinationBranch: Branch.fromJson(json['destinationBranchId'] ?? {}),
      shipments:
          (json['shipmentIds'] as List<dynamic>?)
              ?.map((e) => BranchLogisticsShipment.fromJson(e))
              .toList() ??
          [],
      status: DispatchReceiptStopStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => DispatchReceiptStopStatus.pending,
      ),
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'])
          : null,
      estimatedArrivalSeconds: (json['estimatedArrivalSeconds'] as num?)
          ?.toInt(),
      routeProgress: (json['routeProgress'] as num?)?.toDouble(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      confirmedBy: json['confirmedByUserId'] != null
          ? DispatchReceiptUserRef.fromJson(json['confirmedByUserId'])
          : null,
      confirmationNotes: json['confirmationNotes'] as String?,
      missingShipments:
          (json['missingShipmentIds'] as List<dynamic>?)
              ?.map((e) => BranchLogisticsShipment.fromJson(e))
              .toList() ??
          [],
      damagedShipments:
          (json['damagedShipmentIds'] as List<dynamic>?)
              ?.map((e) => BranchLogisticsShipment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DispatchReceipt {
  final String id;
  final String receiptNumber;
  final Branch sourceBranch;
  final DispatchReceiptUserRef driver;
  final dynamic vehicle;
  final DispatchReceiptUserRef createdBy;
  final DispatchReceiptStatus status;
  final List<DispatchReceiptStop> stops;
  final String planningMethod;
  final List<LatLng> routeGeometry;
  final int? estimatedDurationSeconds;
  final int? totalDistanceMeters;
  final double totalWeightKg;
  final int simulationDurationSeconds;
  final DateTime? simulationStartedAt;
  final double simulationProgress;
  final DateTime? simulationSegmentStartedAt;
  final double viewerRouteEndProgress;
  final DateTime? departedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DispatchReceipt({
    required this.id,
    required this.receiptNumber,
    required this.sourceBranch,
    required this.driver,
    this.vehicle,
    required this.createdBy,
    required this.status,
    required this.stops,
    required this.planningMethod,
    required this.routeGeometry,
    required this.estimatedDurationSeconds,
    required this.totalDistanceMeters,
    required this.totalWeightKg,
    required this.simulationDurationSeconds,
    required this.simulationStartedAt,
    required this.simulationProgress,
    required this.simulationSegmentStartedAt,
    required this.viewerRouteEndProgress,
    this.departedAt,
    this.completedAt,
    this.cancelledAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DispatchReceipt.fromJson(Map<String, dynamic> json) {
    return DispatchReceipt(
      id: json['_id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      sourceBranch: Branch.fromJson(json['sourceBranchId'] ?? {}),
      driver: DispatchReceiptUserRef.fromJson(json['driverId'] ?? {}),
      vehicle: json['vehicleId'],
      createdBy: DispatchReceiptUserRef.fromJson(json['createdByUserId'] ?? {}),
      status: DispatchReceiptStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() == json['status'] ||
            e.name == 'inTransit' && json['status'] == 'IN_TRANSIT',
        orElse: () => DispatchReceiptStatus.created,
      ),
      stops:
          (json['stops'] as List<dynamic>?)
              ?.map((e) => DispatchReceiptStop.fromJson(e))
              .toList() ??
          [],
      planningMethod: json['planningMethod'] as String? ?? 'MANUAL',
      routeGeometry: _resolveRoutePoints(json),
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num?)
          ?.toInt(),
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toInt(),
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0,
      simulationDurationSeconds:
          (json['simulationDurationSeconds'] as num?)?.toInt() ?? 120,
      simulationStartedAt: json['simulationStartedAt'] != null
          ? DateTime.parse(json['simulationStartedAt'])
          : null,
      simulationProgress: (json['simulationProgress'] as num?)?.toDouble() ?? 0,
      simulationSegmentStartedAt: json['simulationSegmentStartedAt'] != null
          ? DateTime.parse(json['simulationSegmentStartedAt'])
          : null,
      viewerRouteEndProgress:
          (json['viewerRouteEndProgress'] as num?)?.toDouble() ?? 1,
      departedAt: json['departedAt'] != null
          ? DateTime.parse(json['departedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isOptimized => planningMethod == 'OPTIMIZED';

  static List<LatLng> _resolveRoutePoints(Map<String, dynamic> json) {
    final directPoints = <LatLng>[];
    final rawPoints = json['routePoints'];
    if (rawPoints is List<dynamic>) {
      for (final rawPoint in rawPoints) {
        double? latitude;
        double? longitude;
        if (rawPoint is Map<String, dynamic>) {
          latitude = (rawPoint['latitude'] as num?)?.toDouble();
          longitude = (rawPoint['longitude'] as num?)?.toDouble();
        } else if (rawPoint is List<dynamic> && rawPoint.length >= 2) {
          latitude = (rawPoint[0] as num?)?.toDouble();
          longitude = (rawPoint[1] as num?)?.toDouble();
        }
        if (latitude == null || longitude == null) continue;
        final point = LatLng(latitude, longitude);
        if (_isValidCoordinate(point)) directPoints.add(point);
      }
    }
    if (directPoints.length >= 2) return directPoints;
    return _decodePolyline(json['routeGeometry'] as String? ?? '');
  }

  static List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];
    for (final precision in const [5, 6]) {
      final points = _decodePolylineAtPrecision(encoded, precision);
      if (points.length >= 2 && points.every(_isValidCoordinate)) {
        return points;
      }
    }
    return const [];
  }

  static List<LatLng> _decodePolylineAtPrecision(
    String encoded,
    int precision,
  ) {
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    final points = <LatLng>[];
    final divisor = precision == 6 ? 1e6 : 1e5;

    try {
      while (index < encoded.length) {
        var shift = 0;
        var result = 0;
        int byte;
        do {
          if (index >= encoded.length) return const [];
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

        shift = 0;
        result = 0;
        do {
          if (index >= encoded.length) return const [];
          byte = encoded.codeUnitAt(index++) - 63;
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
        points.add(LatLng(latitude / divisor, longitude / divisor));
      }
    } on RangeError {
      return const [];
    }
    return points;
  }

  static bool _isValidCoordinate(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}

class AutoPlanDispatchResult {
  final String status;
  final List<DispatchReceipt> receipts;
  final int totalShipments;
  final int assignedShipments;
  final int unassignedShipments;
  final int availableTruckDrivers;
  final int trucksUsed;
  final List<String> unassignedShipmentIds;

  const AutoPlanDispatchResult({
    required this.status,
    required this.receipts,
    required this.totalShipments,
    required this.assignedShipments,
    required this.unassignedShipments,
    required this.availableTruckDrivers,
    required this.trucksUsed,
    required this.unassignedShipmentIds,
  });

  factory AutoPlanDispatchResult.fromJson(Map<String, dynamic> json) {
    final summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AutoPlanDispatchResult(
      status: json['status'] as String? ?? 'SUCCESS',
      receipts: (json['receipts'] as List<dynamic>? ?? [])
          .map((item) => DispatchReceipt.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalShipments: (summary['totalShipments'] as num?)?.toInt() ?? 0,
      assignedShipments: (summary['assignedShipments'] as num?)?.toInt() ?? 0,
      unassignedShipments:
          (summary['unassignedShipments'] as num?)?.toInt() ?? 0,
      availableTruckDrivers:
          (summary['availableTruckDrivers'] as num?)?.toInt() ?? 0,
      trucksUsed: (summary['trucksUsed'] as num?)?.toInt() ?? 0,
      unassignedShipmentIds:
          (json['unassignedShipmentIds'] as List<dynamic>? ?? [])
              .map((id) => id.toString())
              .toList(),
    );
  }
}

class CreateDispatchReceiptStopDto {
  final int stopOrder;
  final String destinationBranchId;
  final List<String> shipmentIds;

  CreateDispatchReceiptStopDto({
    required this.stopOrder,
    required this.destinationBranchId,
    required this.shipmentIds,
  });

  Map<String, dynamic> toJson() => {
    'stopOrder': stopOrder,
    'destinationBranchId': destinationBranchId,
    'shipmentIds': shipmentIds,
  };
}

class CreateDispatchReceiptDto {
  final String driverId;
  final List<CreateDispatchReceiptStopDto> stops;
  final String? notes;

  CreateDispatchReceiptDto({
    required this.driverId,
    required this.stops,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'stops': stops.map((e) => e.toJson()).toList(),
    if (notes != null) 'notes': notes,
  };
}

class ConfirmStopReceiptDto {
  final List<String> missingShipmentIds;
  final List<String> damagedShipmentIds;
  final String? notes;

  ConfirmStopReceiptDto({
    this.missingShipmentIds = const [],
    this.damagedShipmentIds = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (missingShipmentIds.isNotEmpty) 'missingShipmentIds': missingShipmentIds,
    if (damagedShipmentIds.isNotEmpty) 'damagedShipmentIds': damagedShipmentIds,
    if (notes != null) 'notes': notes,
  };
}
