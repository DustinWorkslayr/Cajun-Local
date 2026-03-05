/// Schema-aligned model for `notifications` (backend-cheatsheet §1).
/// Per-user notifications. RLS: own SELECT/UPDATE/DELETE; admin INSERT/DELETE.
library;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.type,
    this.actionUrl,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  /// Optional longer description or detail.
  final String? body;
  /// Category: e.g. deal, reminder, listing, system.
  final String? type;
  /// Optional deep link or URL to open when user taps action.
  final String? actionUrl;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String?,
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
