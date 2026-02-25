/// Schema-aligned model for `business_links` (backend-cheatsheet §1).
library;

class BusinessLink {
  const BusinessLink({
    required this.id,
    required this.url,
    required this.businessId,
    this.label,
    this.sortOrder,
  });

  final String id;
  final String url;
  final String businessId;
  final String? label;
  final int? sortOrder;

  factory BusinessLink.fromJson(Map<String, dynamic> json) {
    return BusinessLink(
      id: json['id'] as String,
      url: json['url'] as String,
      businessId: json['business_id'] as String,
      label: json['label'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }
}
