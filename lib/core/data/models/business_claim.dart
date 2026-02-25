/// Schema-aligned model for `business_claims` (backend-cheatsheet §1).
/// Ownership claim requests; admin approves.
library;

class BusinessClaim {
  const BusinessClaim({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.status,
    this.claimDetails,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String userId;
  final String status;
  final String? claimDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BusinessClaim.fromJson(Map<String, dynamic> json) {
    return BusinessClaim(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      claimDetails: json['claim_details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
