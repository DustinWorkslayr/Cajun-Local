import 'package:cajun_local/features/categories/data/models/subcategory.dart';

class BusinessCategory {
  const BusinessCategory({
    required this.id,
    required this.name,
    required this.bucket,
    this.slug,
    this.icon,
    this.sortOrder,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final String bucket;
  final String? slug;
  final String? icon;
  final int? sortOrder;
  final List<Subcategory> subcategories;

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      bucket: json['bucket'] as String? ?? 'explore',
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
      subcategories:
          (json['subcategories'] as List?)?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>)).toList() ??
          const [],
    );
  }
}
