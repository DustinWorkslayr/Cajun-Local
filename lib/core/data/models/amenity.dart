/// Schema-aligned model for `amenities` (50 total: 15 global + 10 eat + 10 hire + 8 shop + 7 explore).
/// App shows Global + bucket-specific amenities based on business category bucket.
library;

class Amenity {
  const Amenity({
    required this.id,
    required this.name,
    required this.slug,
    required this.bucket,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String slug;
  /// global | eat | hire | shop | explore
  final String bucket;
  final int sortOrder;

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      bucket: json['bucket'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'bucket': bucket,
        'sort_order': sortOrder,
      };
}
