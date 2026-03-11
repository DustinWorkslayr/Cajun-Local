import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/events/data/api/event_rsvps_api.dart';
import 'package:cajun_local/features/events/data/models/event_rsvp.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_rsvps_repository.g.dart';

/// event_rsvps: users manage own RSVPs; admins manage all; viewers see RSVPs for approved events (cheatsheet §2).
class EventRsvpsRepository {
  EventRsvpsRepository({EventRsvpsApi? api}) : _api = api ?? EventRsvpsApi(ApiClient.instance);
  final EventRsvpsApi _api;

  /// Current user's RSVP for an event, if any.
  Future<EventRsvp?> getMyRsvpForEvent(String eventId) async {
    return _api.getMyRsvpForEvent(eventId);
  }

  /// List RSVPs for an event.
  Future<List<EventRsvp>> listByEvent(String eventId) async {
    return _api.listByEvent(eventId);
  }

  /// Counts by status for an event (going, interested, not_going).
  Future<EventRsvpCounts> getCountsForEvent(String eventId) async {
    return _api.getCountsForEvent(eventId);
  }

  /// List current user's RSVPs (for "My RSVPs" section).
  Future<List<EventRsvp>> listMyRsvps() async {
    return _api.listMyRsvps();
  }

  /// Set or update current user's RSVP.
  Future<void> upsert({required String eventId, required String status}) async {
    await _api.upsert(eventId, status);
  }

  /// Remove current user's RSVP.
  Future<void> delete(String eventId) async {
    await _api.delete(eventId);
  }
}

@riverpod
EventRsvpsRepository eventRsvpsRepository(EventRsvpsRepositoryRef ref) {
  return EventRsvpsRepository(api: ref.watch(eventRsvpsApiProvider));
}

class EventRsvpCounts {
  const EventRsvpCounts({this.going = 0, this.interested = 0, this.notGoing = 0});
  final int going;
  final int interested;
  final int notGoing;
  int get total => going + interested + notGoing;
}
