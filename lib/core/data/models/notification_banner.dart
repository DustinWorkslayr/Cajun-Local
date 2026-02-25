/// Schema-aligned model for `notification_banners` (backend-cheatsheet §1).
library;

class NotificationBanner {
  const NotificationBanner({
    required this.id,
    required this.title,
    required this.message,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationBanner.fromJson(Map<String, dynamic> json) {
    return NotificationBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isActive: json['is_active'] as bool? ?? false,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'is_active': isActive,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
}
