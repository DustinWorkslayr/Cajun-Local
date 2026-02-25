/// Schema-aligned model for `email_templates` (backend-cheatsheet §1).
library;

class EmailTemplate {
  const EmailTemplate({
    required this.name,
    required this.subject,
    required this.body,
    this.updatedAt,
  });

  final String name;
  final String subject;
  final String body;
  final DateTime? updatedAt;

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      name: json['name'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'subject': subject, 'body': body};
}
