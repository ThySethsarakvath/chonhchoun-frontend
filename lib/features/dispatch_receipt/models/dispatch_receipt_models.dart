import '../../admin_management/models/branch_model.dart';
import '../../auth/models/user_model.dart';
import '../../branch_logistics/models/branch_logistics_models.dart';

enum DispatchReceiptStatus {
  created,
  inTransit,
  completed,
  cancelled,
}

enum DispatchReceiptStopStatus {
  pending,
  arrived,
  confirmed,
  partial,
}

class DispatchReceiptUserRef {
  final String id;
  final String name;
  final String? phone;

  DispatchReceiptUserRef({
    required this.id,
    required this.name,
    this.phone,
  });

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
      shipments: (json['shipmentIds'] as List<dynamic>?)
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
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      confirmedBy: json['confirmedByUserId'] != null
          ? DispatchReceiptUserRef.fromJson(json['confirmedByUserId'])
          : null,
      confirmationNotes: json['confirmationNotes'] as String?,
      missingShipments: (json['missingShipmentIds'] as List<dynamic>?)
              ?.map((e) => BranchLogisticsShipment.fromJson(e))
              .toList() ??
          [],
      damagedShipments: (json['damagedShipmentIds'] as List<dynamic>?)
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
        (e) => e.name.toUpperCase() == json['status'] ||
               e.name == 'inTransit' && json['status'] == 'IN_TRANSIT',
        orElse: () => DispatchReceiptStatus.created,
      ),
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => DispatchReceiptStop.fromJson(e))
              .toList() ??
          [],
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
        if (missingShipmentIds.isNotEmpty)
          'missingShipmentIds': missingShipmentIds,
        if (damagedShipmentIds.isNotEmpty)
          'damagedShipmentIds': damagedShipmentIds,
        if (notes != null) 'notes': notes,
      };
}
