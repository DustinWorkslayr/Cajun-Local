/// Schema-aligned model for `form_submissions` (messaging-faqs-cheatsheet §5.2).
library;

class FormSubmission {
  const FormSubmission({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.template,
    required this.data,
    this.isRead = false,
    this.createdAt,
    this.businessName,
    this.adminNote,
    this.repliedAt,
    this.repliedBy,
  });

  final String id;
  final String businessId;
  final String userId;
  final String template;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;
  /// Resolved business name (not in DB; set when listing for manager).
  final String? businessName;
  /// Internal note or reply; visible to manager and admin.
  final String? adminNote;
  final DateTime? repliedAt;
  final String? repliedBy;

  factory FormSubmission.fromJson(Map<String, dynamic> json) {
    return FormSubmission(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      template: json['template'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      adminNote: json['admin_note'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.tryParse(json['replied_at'] as String)
          : null,
      repliedBy: json['replied_by'] as String?,
    );
  }
}
