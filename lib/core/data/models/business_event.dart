/// Schema-aligned model for `business_events` (backend-cheatsheet §1).
library;

class BusinessEvent {
  const BusinessEvent({
    required this.id,
    required this.businessId,
    required this.title,
    required this.eventDate,
    this.description,
    this.endDate,
    this.location,
    this.imageUrl,
    this.status = 'pending',
  });

  final String id;
  final String businessId;
  final String title;
  final DateTime eventDate;
  final String? description;
  final DateTime? endDate;
  final String? location;
  final String? imageUrl;
  final String status;

  factory BusinessEvent.fromJson(Map<String, dynamic> json) {
    return BusinessEvent(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      description: json['description'] as String?,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
