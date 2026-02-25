/// Schema-aligned model for `business_subscriptions` (pricing-and-ads-cheatsheet §2.2).
/// One subscription per business (UNIQUE business_id). Admin-only write.
library;

class BusinessSubscription {
  const BusinessSubscription({
    required this.id,
    required this.businessId,
    required this.planId,
    this.status = 'active',
    this.billingInterval = 'monthly',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    this.canceledAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String planId;
  final String status;
  final String billingInterval;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final DateTime? canceledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BusinessSubscription.fromJson(Map<String, dynamic> json) {
    return BusinessSubscription(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String? ?? 'active',
      billingInterval: json['billing_interval'] as String? ?? 'monthly',
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.tryParse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'] as String)
          : null,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      canceledAt: json['canceled_at'] != null
          ? DateTime.tryParse(json['canceled_at'] as String)
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
        'business_id': businessId,
        'plan_id': planId,
        'status': status,
        'billing_interval': billingInterval,
        if (currentPeriodStart != null)
          'current_period_start':
              currentPeriodStart!.toUtc().toIso8601String(),
        if (currentPeriodEnd != null)
          'current_period_end': currentPeriodEnd!.toUtc().toIso8601String(),
        if (stripeSubscriptionId != null)
          'stripe_subscription_id': stripeSubscriptionId,
        if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
        if (canceledAt != null)
          'canceled_at': canceledAt!.toUtc().toIso8601String(),
      };
}
