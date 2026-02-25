/// Schema-aligned model for `parishes` table.
/// Public read; admin write.
library;

class Parish {
  const Parish({
    required this.id,
    required this.name,
    this.slug,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  /// URL-safe slug (auto-generated from name in DB). Unique.
  final String? slug;
  final int sortOrder;

  factory Parish.fromJson(Map<String, dynamic> json) {
    return Parish(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'sort_order': sortOrder,
      };
}
