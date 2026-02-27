/// Schema-aligned model for `business_ads` (pricing-and-ads-cheatsheet §2.6).
/// Managers can SELECT/INSERT; admin can UPDATE/DELETE. impressions/clicks/approved_* server-only.
library;

class BusinessAd {
  const BusinessAd({
    required this.id,
    required this.businessId,
    required this.packageId,
    required this.status,
    this.startDate,
    this.endDate,
    this.headline,
    this.imageUrl,
    this.targetUrl,
    this.impressions = 0,
    this.clicks = 0,
    this.stripePaymentId,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.packageName,
    this.placement,
  });

  final String id;
  final String businessId;
  final String packageId;
  /// draft, pending_payment, pending_approval, active, paused, expired, rejected
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? headline;
  final String? imageUrl;
  final String? targetUrl;
  final int impressions;
  final int clicks;
  final String? stripePaymentId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Joined from ad_packages when needed
  final String? packageName;
  final String? placement;

  factory BusinessAd.fromJson(Map<String, dynamic> json) {
    return BusinessAd(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      packageId: json['package_id'] as String,
      status: json['status'] as String? ?? 'draft',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      headline: json['headline'] as String?,
      imageUrl: json['image_url'] as String?,
      targetUrl: json['target_url'] as String?,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      stripePaymentId: json['stripe_payment_id'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      packageName: json['package_name'] as String?,
      placement: json['placement'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'package_id': packageId,
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'headline': headline,
        'image_url': imageUrl,
        'target_url': targetUrl,
      };

  static String statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending_payment':
        return 'Pending payment';
      case 'pending_approval':
        return 'Pending approval';
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'expired':
        return 'Expired';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
