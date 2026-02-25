import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/event_rsvp.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// event_rsvps: users manage own RSVPs; admins manage all; viewers see RSVPs for approved events (cheatsheet §2).
class EventRsvpsRepository {
  EventRsvpsRepository({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 2000;

  /// Current user's RSVP for an event, if any.
  Future<EventRsvp?> getMyRsvpForEvent(String eventId) async {
    final client = _client;
    final uid = _auth.currentUserId;
    if (client == null || uid == null) return null;
    final res = await client
        .from('event_rsvps')
        .select()
        .eq('event_id', eventId)
        .eq('user_id', uid)
        .maybeSingle();
    if (res == null) return null;
    return EventRsvp.fromJson(Map<String, dynamic>.from(res));
  }

  /// List RSVPs for an event (RLS: own, admin, or approved-event viewers).
  Future<List<EventRsvp>> listByEvent(String eventId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('event_rsvps')
        .select()
        .eq('event_id', eventId)
        .limit(_limit);
    return (list as List)
        .map((e) => EventRsvp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Counts by status for an event (going, interested, not_going).
  Future<EventRsvpCounts> getCountsForEvent(String eventId) async {
    final list = await listByEvent(eventId);
    int going = 0, interested = 0, notGoing = 0;
    for (final r in list) {
      switch (r.status) {
        case 'going':
          going++;
          break;
        case 'interested':
          interested++;
          break;
        case 'not_going':
          notGoing++;
          break;
      }
    }
    return EventRsvpCounts(going: going, interested: interested, notGoing: notGoing);
  }

  /// List current user's RSVPs (for "My RSVPs" section).
  Future<List<EventRsvp>> listMyRsvps() async {
    final client = _client;
    final uid = _auth.currentUserId;
    if (client == null || uid == null) return [];
    final list = await client
        .from('event_rsvps')
        .select()
        .eq('user_id', uid)
        .order('updated_at', ascending: false)
        .limit(_limit);
    return (list as List)
        .map((e) => EventRsvp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Set or update current user's RSVP. Upsert: (event_id, user_id) unique.
  Future<void> upsert({required String eventId, required String status}) async {
    final client = _client;
    final uid = _auth.currentUserId;
    if (client == null || uid == null) return;
    final id = 'r-$eventId-$uid';
    await client.from('event_rsvps').upsert(
      {
        'id': id,
        'event_id': eventId,
        'user_id': uid,
        'status': status,
      },
      onConflict: 'event_id,user_id',
    );
  }

  /// Remove current user's RSVP.
  Future<void> delete(String eventId) async {
    final client = _client;
    final uid = _auth.currentUserId;
    if (client == null || uid == null) return;
    await client
        .from('event_rsvps')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', uid);
  }
}

class EventRsvpCounts {
  const EventRsvpCounts({
    this.going = 0,
    this.interested = 0,
    this.notGoing = 0,
  });
  final int going;
  final int interested;
  final int notGoing;
  int get total => going + interested + notGoing;
}
