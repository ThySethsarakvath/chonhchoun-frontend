import '../../../features/auth/models/auth_models.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? avatarUrl;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['avatarUrl'] as String?;

    return CustomerProfile(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'customer') as String,
      isActive: (json['isActive'] ?? true) as bool,
      avatarUrl: rawAvatar == null || rawAvatar.trim().isEmpty
          ? null
          : rawAvatar,
    );
  }

  factory CustomerProfile.fromAuthUser(AuthUser user) {
    return CustomerProfile(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      avatarUrl: user.avatarUrl,
    );
  }

  AuthUser toAuthUser() {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      role: role,
      isActive: isActive,
      avatarUrl: avatarUrl,
    );
  }
}
