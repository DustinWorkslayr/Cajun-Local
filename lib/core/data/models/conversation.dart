/// Schema-aligned model for `conversations` (messaging-faqs-cheatsheet §1.1).
library;

class Conversation {
  const Conversation({
    required this.id,
    required this.businessId,
    required this.userId,
    this.subject,
    this.isArchived = false,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String userId;
  final String? subject;
  final bool isArchived;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      subject: json['subject'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
