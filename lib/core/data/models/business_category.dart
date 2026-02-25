/// Schema-aligned model for `business_categories` (backend-cheatsheet §1).
/// Public read: all rows. [bucket] groups categories: hire, eat, shop, explore.
library;

class BusinessCategory {
  const BusinessCategory({
    required this.id,
    required this.name,
    required this.bucket,
    this.slug,
    this.icon,
    this.sortOrder,
  });

  final String id;
  final String name;
  /// Grouping bucket: hire | eat | shop | explore.
  final String bucket;
  /// URL-safe slug (auto-generated from name in DB). Unique.
  final String? slug;
  final String? icon;
  final int? sortOrder;

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      bucket: json['bucket'] as String? ?? 'explore',
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }
}
