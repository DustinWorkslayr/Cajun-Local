/// Schema-aligned model for `user_deals` (backend-cheatsheet §1).
/// Tracks claimed deals per user. RLS: own SELECT/INSERT; UPDATE/DELETE admin only.
library;

class UserDeal {
  const UserDeal({
    required this.userId,
    required this.dealId,
    required this.claimedAt,
    this.usedAt,
  });

  final String userId;
  final String dealId;
  final DateTime claimedAt;
  final DateTime? usedAt;

  factory UserDeal.fromJson(Map<String, dynamic> json) {
    return UserDeal(
      userId: json['user_id'] as String,
      dealId: json['deal_id'] as String,
      claimedAt: DateTime.parse(json['claimed_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'] as String)
          : null,
    );
  }
}
