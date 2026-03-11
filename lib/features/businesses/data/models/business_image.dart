/// Schema-aligned model for `business_images` (backend-cheatsheet §1).
library;

class BusinessImage {
  const BusinessImage({
    required this.id,
    required this.url,
    required this.businessId,
    required this.status,
    this.sortOrder,
  });

  final String id;
  final String url;
  final String businessId;
  final String status;
  final int? sortOrder;

  factory BusinessImage.fromJson(Map<String, dynamic> json) {
    return BusinessImage(
      id: json['id'] as String,
      url: json['url'] as String,
      businessId: json['business_id'] as String,
      status: json['status'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }
}
