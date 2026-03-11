/// Schema-aligned model for `user_plans` (pricing-and-ads-cheatsheet §2.3).
/// Admin-only write; public SELECT.
library;

class UserPlan {
  const UserPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.priceMonthly,
    required this.priceYearly,
    this.features = const {},
    this.stripePriceIdMonthly,
    this.stripePriceIdYearly,
    this.stripeProductId,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String tier;
  final double priceMonthly;
  final double priceYearly;
  final Map<String, dynamic> features;
  /// Stripe Price ID for monthly billing (from Stripe Dashboard).
  final String? stripePriceIdMonthly;
  /// Stripe Price ID for yearly billing (from Stripe Dashboard).
  final String? stripePriceIdYearly;
  /// Stripe Product ID for tier mapping (from Stripe Dashboard).
  final String? stripeProductId;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserPlan.fromJson(Map<String, dynamic> json) {
    return UserPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: json['tier'] as String,
      priceMonthly: _toDouble(json['price_monthly']),
      priceYearly: _toDouble(json['price_yearly']),
      features: json['features'] != null
          ? Map<String, dynamic>.from(json['features'] as Map)
          : {},
      stripePriceIdMonthly: json['stripe_price_id_monthly'] as String?,
      stripePriceIdYearly: json['stripe_price_id_yearly'] as String?,
      stripeProductId: json['stripe_product_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tier': tier,
        'price_monthly': priceMonthly,
        'price_yearly': priceYearly,
        'features': features,
        'stripe_price_id_monthly': stripePriceIdMonthly,
        'stripe_price_id_yearly': stripePriceIdYearly,
        'stripe_product_id': stripeProductId,
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}
