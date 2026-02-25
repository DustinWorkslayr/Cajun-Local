/// Schema-aligned model for `subcategories` (backend-cheatsheet §1).
library;

class Subcategory {
  const Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.slug,
  });

  final String id;
  final String name;
  final String categoryId;
  /// URL-safe slug (auto-generated: category-slug + '-' + name). Unique.
  final String? slug;

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      slug: json['slug'] as String?,
    );
  }
}
