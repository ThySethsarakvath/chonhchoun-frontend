class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isActive;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.isActive,
    this.avatarUrl,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        avatarUrl: json['avatarUrl'] as String?,
      );
}