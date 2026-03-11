/// Schema-aligned model for `user_punch_cards` (backend-cheatsheet §1, §4).
/// Per-user enrollment in a punch card program. RLS: own or admin.
/// current_punches and is_redeemed are only updated by validate_and_punch / redeem_punch_card.
library;

class UserPunchCard {
  const UserPunchCard({
    required this.id,
    required this.userId,
    required this.programId,
    required this.currentPunches,
    required this.isRedeemed,
    this.createdAt,
    this.redeemedAt,
  });

  final String id;
  final String userId;
  final String programId;
  final int currentPunches;
  final bool isRedeemed;
  final DateTime? createdAt;
  final DateTime? redeemedAt;

  factory UserPunchCard.fromJson(Map<String, dynamic> json) {
    return UserPunchCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      programId: json['program_id'] as String,
      currentPunches: (json['current_punches'] as num?)?.toInt() ?? 0,
      isRedeemed: json['is_redeemed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.tryParse(json['redeemed_at'] as String)
          : null,
    );
  }
}
