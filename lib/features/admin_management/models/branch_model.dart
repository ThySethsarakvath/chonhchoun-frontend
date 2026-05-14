class Branch {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? description;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.description,
    required this.isActive,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'],
      name: json['name'],
      code: json['code'],
      address: json['address'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
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