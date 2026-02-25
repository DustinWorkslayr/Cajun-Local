/// Schema-aligned model for `reviews` (backend-cheatsheet §1).
/// Moderation: status pending/approved/rejected.
library;

class Review {
  const Review({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.rating,
    required this.status,
    this.body,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String userId;
  final int rating;
  final String status;
  final String? body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      rating: (json['rating'] as num).toInt(),
      status: json['status'] as String,
      body: json['body'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
