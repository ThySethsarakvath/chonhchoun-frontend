class Branch {
  final String id;
  final String name;
  final int? branchNumber;
  final String? code;
  final String? address;
  final String? description;
  final bool isActive;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? status;
  final String? logoUrl;
  final bool isVisibleOnMap;
  final String? ownerName;


  Branch({
    required this.id,
    required this.name,
    this.branchNumber,
    this.code,
    this.address,
    this.description,
    this.lat,
    this.lng,
    required this.isActive,
    this.phone,
    this.status,
    this.logoUrl,
    required this.isVisibleOnMap,
    this.ownerName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final owner = json['ownerId'];
    return Branch(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      branchNumber: json['branchNumber'] as int?,
      code: json['code'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] ?? true,
      lat: latitude is num
          ? latitude.toDouble()
          : (loc != null && loc['lat'] is num)
              ? (loc['lat'] as num).toDouble()
              : null,
      lng: longitude is num
          ? longitude.toDouble()
          : (loc != null && loc['lng'] is num)
              ? (loc['lng'] as num).toDouble()
              : null,
      phone: json['phone'] as String?,
      status: json['status'] as String?,
      logoUrl: json['logoUrl'] as String?,
      isVisibleOnMap: json['isVisibleOnMap'] as bool? ?? true,
      ownerName: owner is Map<String, dynamic> ? owner['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'address': address,
        'description': description,
        'branchNumber': branchNumber,
        'isActive': isActive,
        'phone': phone,
        'status': status,
        'logoUrl': logoUrl,
        'isVisibleOnMap': isVisibleOnMap,
      };
}
