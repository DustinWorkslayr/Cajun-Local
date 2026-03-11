/// Schema-aligned model for `menu_items` (backend-cheatsheet §1).
library;

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.sectionId,
    this.price,
    this.description,
    this.isAvailable,
  });

  final String id;
  final String name;
  final String sectionId;
  final String? price;
  final String? description;
  final bool? isAvailable;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      sectionId: json['section_id'] as String,
      price: _priceFromJson(json['price']),
      description: json['description'] as String?,
      isAvailable: json['is_available'] as bool?,
    );
  }

  /// DB may return price as numeric (double) or text; normalize to String?.
  static String? _priceFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is num) return value.toString();
    return null;
  }
}
