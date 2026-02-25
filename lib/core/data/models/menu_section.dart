/// Schema-aligned model for `menu_sections` (backend-cheatsheet §1).
library;

class MenuSection {
  const MenuSection({
    required this.id,
    required this.name,
    required this.businessId,
    this.sortOrder,
  });

  final String id;
  final String name;
  final String businessId;
  final int? sortOrder;

  factory MenuSection.fromJson(Map<String, dynamic> json) {
    return MenuSection(
      id: json['id'] as String,
      name: json['name'] as String,
      businessId: json['business_id'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }
}
