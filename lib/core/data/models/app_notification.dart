/// Schema-aligned model for `notifications` (backend-cheatsheet §1).
/// Per-user notifications. RLS: own SELECT/UPDATE; admin INSERT/DELETE.
library;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.type,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
