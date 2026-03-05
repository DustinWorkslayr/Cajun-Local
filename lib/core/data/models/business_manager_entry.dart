/// One row from list_business_managers RPC: a user with access to a business.
class BusinessManagerEntry {
  const BusinessManagerEntry({
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
  });

  final String userId;
  final String role;
  final String? displayName;
  final String? email;

  factory BusinessManagerEntry.fromJson(Map<String, dynamic> json) {
    return BusinessManagerEntry(
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'owner',
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
    );
  }
}
