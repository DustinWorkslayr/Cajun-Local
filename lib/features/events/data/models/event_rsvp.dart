/// Schema-aligned model for `event_rsvps` (backend-cheatsheet §1).
/// User RSVP to a business event: going, interested, not_going. Unique (event_id, user_id).
library;

class EventRsvp {
  const EventRsvp({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.updatedAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String status; // going | interested | not_going
  final DateTime? updatedAt;

  factory EventRsvp.fromJson(Map<String, dynamic> json) {
    return EventRsvp(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'interested',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
