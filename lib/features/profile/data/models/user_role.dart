/// Role model aligned with the FastAPI backend.
/// Two roles only: 'admin' and 'user'.
library;

class UserRole {
  const UserRole({required this.userId, required this.role});

  final String userId;
  final String role;

  static const String admin = 'admin';
  static const String user = 'user';

  bool get isAdmin => role == admin;

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(userId: json['user_id'] as String, role: json['role'] as String);
  }
}
