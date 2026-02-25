/// Schema-aligned model for `messages` (messaging-faqs-cheatsheet §1.2).
library;

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'body': body,
        'is_read': isRead,
      };
}
