/// Schema-aligned model for `payment_history` (pricing-and-ads-cheatsheet §2.8).
/// SELECT by own user/business manager/admin; no client writes.
library;

class PaymentHistoryEntry {
  const PaymentHistoryEntry({
    required this.id,
    this.userId,
    this.businessId,
    required this.amount,
    this.currency = 'usd',
    required this.paymentType,
    this.referenceId,
    this.stripePaymentIntentId,
    this.status = 'succeeded',
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String? businessId;
  final double amount;
  final String currency;
  /// business_subscription, user_subscription, advertisement
  final String paymentType;
  final String? referenceId;
  final String? stripePaymentIntentId;
  final String status;
  final DateTime? createdAt;

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      businessId: json['business_id'] as String?,
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'usd',
      paymentType: json['payment_type'] as String,
      referenceId: json['reference_id'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      status: json['status'] as String? ?? 'succeeded',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String paymentTypeLabel(String type) {
    switch (type) {
      case 'business_subscription':
        return 'Business subscription';
      case 'user_subscription':
        return 'User subscription';
      case 'advertisement':
        return 'Advertisement';
      default:
        return type;
    }
  }
}
