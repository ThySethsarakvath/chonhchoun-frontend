class DriverManagementSummary {
  final int totalDrivers;
  final int availableDrivers;
  final int totalVehicles;
  final int companyVehicles;
  final int ownVehicleDrivers;
  final int pendingApplications;

  const DriverManagementSummary({
    required this.totalDrivers,
    required this.availableDrivers,
    required this.totalVehicles,
    required this.companyVehicles,
    required this.ownVehicleDrivers,
    required this.pendingApplications,
  });

  factory DriverManagementSummary.fromJson(Map<String, dynamic> json) {
    return DriverManagementSummary(
      totalDrivers: json['totalDrivers'] as int? ?? 0,
      availableDrivers: json['availableDrivers'] as int? ?? 0,
      totalVehicles: json['totalVehicles'] as int? ?? 0,
      companyVehicles: json['companyVehicles'] as int? ?? 0,
      ownVehicleDrivers: json['ownVehicleDrivers'] as int? ?? 0,
      pendingApplications: json['pendingApplications'] as int? ?? 0,
    );
  }
}

class ManagedVehicle {
  final String id;
  final String code;
  final String? plateNumber;
  final String? type;
  final String ownershipType;
  final String? branchId;
  final String? branchName;
  final String? branchCode;
  final String? ownerDriverId;
  final String? ownerDriverName;
  final double? maxWeightKg;
  final double? maxVolumeM3;
  final int? maxPackageCount;
  final String? currentWarehouse;
  final String status;
  final bool isActive;

  const ManagedVehicle({
    required this.id,
    required this.code,
    this.plateNumber,
    this.type,
    required this.ownershipType,
    this.branchId,
    this.branchName,
    this.branchCode,
    this.ownerDriverId,
    this.ownerDriverName,
    this.maxWeightKg,
    this.maxVolumeM3,
    this.maxPackageCount,
    this.currentWarehouse,
    required this.status,
    required this.isActive,
  });

  bool get isCompanyVehicle => ownershipType == 'COMPANY';

  factory ManagedVehicle.fromJson(Map<String, dynamic> json) {
    final weight = json['maxWeightKg'];
    final volume = json['maxVolumeM3'];
    return ManagedVehicle(
      id: json['_id'] as String,
      code: json['code'] as String? ?? '',
      plateNumber: json['plateNumber'] as String?,
      type: json['type'] as String?,
      ownershipType: json['ownershipType'] as String? ?? 'COMPANY',
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      branchCode: json['branchCode'] as String?,
      ownerDriverId: json['ownerDriverId'] as String?,
      ownerDriverName: json['ownerDriverName'] as String?,
      maxWeightKg: weight is num ? weight.toDouble() : null,
      maxVolumeM3: volume is num ? volume.toDouble() : null,
      maxPackageCount: json['maxPackageCount'] as int?,
      currentWarehouse: json['currentWarehouse'] as String?,
      status: json['status'] as String? ?? 'AVAILABLE',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class DriverVehicleAssignmentView {
  final String id;
  final String assignmentType;
  final DateTime? assignedAt;
  final ManagedVehicle? vehicle;

  const DriverVehicleAssignmentView({
    required this.id,
    required this.assignmentType,
    this.assignedAt,
    this.vehicle,
  });

  factory DriverVehicleAssignmentView.fromJson(Map<String, dynamic> json) {
    return DriverVehicleAssignmentView(
      id: json['_id'] as String,
      assignmentType: json['assignmentType'] as String? ?? 'PRIMARY',
      assignedAt: json['assignedAt'] is String
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? ManagedVehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ManagedDriver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? vehicleType;
  final String? assignedVehicleCode;
  final String availabilityStatus;
  final List<String> supportedVehicleTypes;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final double? maxLoadWeightKg;
  final int? maxPackageCount;
  final String? avatarUrl;
  final bool isActive;
  final List<DriverVehicleAssignmentView> assignments;

  const ManagedDriver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.vehicleType,
    this.assignedVehicleCode,
    required this.availabilityStatus,
    required this.supportedVehicleTypes,
    this.licenseNumber,
    this.licenseExpiry,
    this.maxLoadWeightKg,
    this.maxPackageCount,
    this.avatarUrl,
    required this.isActive,
    required this.assignments,
  });

  factory ManagedDriver.fromJson(Map<String, dynamic> json) {
    final weight = json['maxLoadWeightKg'];
    return ManagedDriver(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vehicleType: json['vehicleType'] as String?,
      assignedVehicleCode: json['assignedVehicleCode'] as String?,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'OFFLINE',
      supportedVehicleTypes: (json['supportedVehicleTypes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      licenseNumber: json['licenseNumber'] as String?,
      licenseExpiry: json['licenseExpiry'] is String
          ? DateTime.tryParse(json['licenseExpiry'] as String)
          : null,
      maxLoadWeightKg: weight is num ? weight.toDouble() : null,
      maxPackageCount: json['maxPackageCount'] as int?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      assignments: (json['assignments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DriverVehicleAssignmentView.fromJson)
          .toList(),
    );
  }
}

class BranchDriverManagementOverview {
  final String branchId;
  final String branchName;
  final int? branchNumber;
  final String? branchCode;
  final DriverManagementSummary summary;
  final List<ManagedDriver> drivers;
  final List<ManagedVehicle> vehicles;

  const BranchDriverManagementOverview({
    required this.branchId,
    required this.branchName,
    this.branchNumber,
    this.branchCode,
    required this.summary,
    required this.drivers,
    required this.vehicles,
  });

  factory BranchDriverManagementOverview.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] as Map<String, dynamic>? ?? const {};
    return BranchDriverManagementOverview(
      branchId: branch['_id'] as String? ?? '',
      branchName: branch['name'] as String? ?? '',
      branchNumber: branch['branchNumber'] as int?,
      branchCode: branch['code'] as String?,
      summary: DriverManagementSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      drivers: (json['drivers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedDriver.fromJson)
          .toList(),
      vehicles: (json['vehicles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedVehicle.fromJson)
          .toList(),
    );
  }
}
