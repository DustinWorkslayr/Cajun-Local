/// Schema-aligned model for `user_roles` (backend-cheatsheet §2).
/// RLS: user can SELECT own row; only admin can INSERT/UPDATE/DELETE.
library;

class UserRole {
  const UserRole({
    required this.userId,
    required this.role,
  });

  final String userId;
  final String role;

  static const String superAdmin = 'super_admin';
  static const String admin = 'admin';
  static const String businessOwner = 'business_owner';
  static const String user = 'user';

  bool get isAdmin => role == admin || role == superAdmin;

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      userId: json['user_id'] as String,
      role: json['role'] as String,
    );
  }
}
