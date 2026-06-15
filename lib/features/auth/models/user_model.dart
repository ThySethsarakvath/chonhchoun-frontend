class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? vehicleType;
  final String? assignedVehicleCode;
  final String? availabilityStatus;
  final List<String> supportedVehicleTypes;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final double? maxLoadWeightKg;
  final int? maxPackageCount;
  final String? phone;
  final bool isActive;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.vehicleType,
    this.assignedVehicleCode,
    this.availabilityStatus,
    this.supportedVehicleTypes = const [],
    this.licenseNumber,
    this.licenseExpiry,
    this.maxLoadWeightKg,
    this.maxPackageCount,
    this.phone,
    required this.isActive,
    this.avatarUrl,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        vehicleType: (json['vehicleType'] as String?)?.isEmpty == true
            ? null
            : json['vehicleType'] as String?,
        assignedVehicleCode:
            (json['assignedVehicleCode'] as String?)?.isEmpty == true
                ? null
                : json['assignedVehicleCode'] as String?,
        availabilityStatus: json['availabilityStatus'] as String?,
        supportedVehicleTypes:
            (json['supportedVehicleTypes'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
        licenseNumber: json['licenseNumber'] as String?,
        licenseExpiry: json['licenseExpiry'] is String
            ? DateTime.tryParse(json['licenseExpiry'] as String)
            : null,
        maxLoadWeightKg: json['maxLoadWeightKg'] is num
            ? (json['maxLoadWeightKg'] as num).toDouble()
            : null,
        maxPackageCount: json['maxPackageCount'] as int?,
        phone: json['phone'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class DriverCurrentVehicle {
  final String id;
  final String code;
  final String? plateNumber;
  final String? type;
  final String ownershipType;
  final String status;
  final bool isActive;
  final double? maxWeightKg;
  final int? maxPackageCount;

  const DriverCurrentVehicle({
    required this.id,
    required this.code,
    this.plateNumber,
    this.type,
    required this.ownershipType,
    required this.status,
    required this.isActive,
    this.maxWeightKg,
    this.maxPackageCount,
  });

  factory DriverCurrentVehicle.fromJson(Map<String, dynamic> json) {
    return DriverCurrentVehicle(
      id: json['_id'] as String,
      code: json['code'] as String? ?? '',
      plateNumber: json['plateNumber'] as String?,
      type: json['type'] as String?,
      ownershipType: json['ownershipType'] as String? ?? 'COMPANY',
      status: json['status'] as String? ?? 'AVAILABLE',
      isActive: json['isActive'] as bool? ?? true,
      maxWeightKg: json['maxWeightKg'] is num
          ? (json['maxWeightKg'] as num).toDouble()
          : null,
      maxPackageCount: json['maxPackageCount'] as int?,
    );
  }
}

class DriverStateSnapshot {
  final UserProfile profile;
  final DriverCurrentVehicle? currentVehicle;
  final DateTime? assignedAt;
  final String? assignmentType;

  const DriverStateSnapshot({
    required this.profile,
    required this.currentVehicle,
    this.assignedAt,
    this.assignmentType,
  });

  factory DriverStateSnapshot.fromJson(Map<String, dynamic> json) {
    final assignment = json['activeAssignment'] as Map<String, dynamic>?;
    return DriverStateSnapshot(
      profile: UserProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
      currentVehicle: json['currentVehicle'] is Map<String, dynamic>
          ? DriverCurrentVehicle.fromJson(
              json['currentVehicle'] as Map<String, dynamic>,
            )
          : null,
      assignedAt: assignment?['assignedAt'] is String
          ? DateTime.tryParse(assignment!['assignedAt'] as String)
          : null,
      assignmentType: assignment?['assignmentType'] as String?,
    );
  }
}
