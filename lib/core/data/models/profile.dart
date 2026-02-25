/// Schema-aligned model for `profiles` (backend-cheatsheet §1).
/// Created by handle_new_user trigger. RLS: own or admin.
library;

class Profile {
  const Profile({
    required this.userId,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.updatedAt,
  });

  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
