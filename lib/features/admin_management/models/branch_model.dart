class Branch {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? description;
  final bool isActive;
  final double? lat;
  final double? lng;


  Branch({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.description,
    this.lat,
    this.lng,
    required this.isActive,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return Branch(
      id: json['_id'],
      name: json['name'],
      code: json['code'],
      isActive: json['isActive'] ?? true,
      lat: loc != null ? (loc['lat'] as num).toDouble() : null,
      lng: loc != null ? (loc['lng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'address': address,
        'description': description,
        'isActive': isActive,
      };
}