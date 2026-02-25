/// Schema-aligned model for `user_subscriptions` (pricing-and-ads-cheatsheet §2.4).
/// One subscription per user (UNIQUE user_id). Admin-only write.
library;

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.status = 'active',
    this.billingInterval = 'monthly',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String planId;
  final String status;
  final String billingInterval;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String? ?? 'active',
      billingInterval: json['billing_interval'] as String? ?? 'monthly',
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.tryParse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'plan_id': planId,
        'status': status,
        'billing_interval': billingInterval,
        if (currentPeriodStart != null)
          'current_period_start': currentPeriodStart!.toUtc().toIso8601String(),
        if (currentPeriodEnd != null)
          'current_period_end': currentPeriodEnd!.toUtc().toIso8601String(),
      };
}
