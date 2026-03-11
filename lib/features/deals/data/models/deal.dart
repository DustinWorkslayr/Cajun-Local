/// Schema-aligned model for `deals` (backend-cheatsheet §1).
library;

class Deal {
  const Deal({
    required this.id,
    required this.title,
    required this.businessId,
    required this.dealType,
    required this.status,
    this.description,
    this.startDate,
    this.endDate,
    this.isActive,
  });

  final String id;
  final String title;
  final String businessId;
  final String dealType;
  final String status;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      title: json['title'] as String,
      businessId: json['business_id'] as String,
      dealType: json['deal_type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool?,
    );
  }
}
