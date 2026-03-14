/// Schema-aligned model for `user_punch_cards` (backend-cheatsheet §1).
/// Tracks user enrollment and progress in a loyalty program.
library;

class UserPunchCard {
  const UserPunchCard({
    required this.id,
    required this.userId,
    required this.programId,
    required this.currentPunches,
    required this.isRedeemed,
    this.redeemedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String programId;
  final int currentPunches;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserPunchCard.fromJson(Map<String, dynamic> json) {
    return UserPunchCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      programId: json['program_id'] as String,
      currentPunches: json['current_punches'] ?? 0,
      isRedeemed: json['is_redeemed'] ?? false,
      redeemedAt: json['redeemed_at'] != null ? DateTime.parse(json['redeemed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'program_id': programId,
      'current_punches': currentPunches,
      'is_redeemed': isRedeemed,
      'redeemed_at': redeemedAt?.toIso8601String(),
    };
  }
}
