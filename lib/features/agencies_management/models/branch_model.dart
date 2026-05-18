class Branch {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  // NEW: Add these fields for tracking [cite: 75, 80]
  final double? lat;
  final double? lng;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.lat,
    this.lng,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    
    final loc = json['location'] as Map<String, dynamic>?;
    
    return Branch(
      id: json['_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['isActive'] as bool? ?? true,
      // Map the nested backend values to model properties 
      lat: loc != null ? (loc['lat'] as num).toDouble() : null,
      lng: loc != null ? (loc['lng'] as num).toDouble() : null,
    );
  }
}