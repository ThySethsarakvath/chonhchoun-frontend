class Branch {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.description,
    required this.isActive,
    this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
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