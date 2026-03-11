/// Schema-aligned model for `category_banners` (backend-cheatsheet §1).
library;

class CategoryBanner {
  const CategoryBanner({
    required this.id,
    required this.categoryId,
    required this.imageUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String imageUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryBanner.fromJson(Map<String, dynamic> json) {
    return CategoryBanner(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      imageUrl: json['image_url'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
