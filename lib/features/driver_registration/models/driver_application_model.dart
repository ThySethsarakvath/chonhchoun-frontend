class DriverApplicationBranch {
  final String id;
  final String name;
  final int? branchNumber;
  final String? address;
  final String? phone;

  const DriverApplicationBranch({
    required this.id,
    required this.name,
    this.branchNumber,
    this.address,
    this.phone,
  });

  factory DriverApplicationBranch.fromJson(Map<String, dynamic> json) {
    return DriverApplicationBranch(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      branchNumber: json['branchNumber'] as int?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class DriverApplication {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final DriverApplicationBranch? branch;
  final String? avatarUrl;
  final String? cvUrl;
  final String? nationalIdUrl;
  final String? drivingLicenseUrl;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const DriverApplication({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.branch,
    this.avatarUrl,
    this.cvUrl,
    this.nationalIdUrl,
    this.drivingLicenseUrl,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory DriverApplication.fromJson(Map<String, dynamic> json) {
    return DriverApplication(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      branch: json['branch'] is Map<String, dynamic>
          ? DriverApplicationBranch.fromJson(
              json['branch'] as Map<String, dynamic>,
            )
          : null,
      avatarUrl: json['avatarUrl'] as String?,
      cvUrl: json['cvUrl'] as String?,
      nationalIdUrl: json['nationalIdUrl'] as String?,
      drivingLicenseUrl: json['drivingLicenseUrl'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] is String
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
    );
  }
}

class BranchDriver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  const BranchDriver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.isActive,
    this.createdAt,
  });

  factory BranchDriver.fromJson(Map<String, dynamic> json) {
    return BranchDriver(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
