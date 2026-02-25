import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// business_events: manager/admin CRUD; public read when status = approved (§7).
class BusinessEventsRepository {
  BusinessEventsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _approved = 'approved';
  static const _limit = 1000;

  /// List events for a business (manager sees all statuses; RLS enforces).
  Future<List<BusinessEvent>> listForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_events')
        .select()
        .eq('business_id', businessId)
        .order('event_date', ascending: true)
        .limit(_limit);
    return (list as List)
        .map((e) => BusinessEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single event by id (for detail/analytics). RLS applies.
  Future<BusinessEvent?> getById(String eventId) async {
    final client = _client;
    if (client == null) return null;
    final res = await client
        .from('business_events')
        .select()
        .eq('id', eventId)
        .maybeSingle();
    if (res == null) return null;
    return BusinessEvent.fromJson(res);
  }

  /// Public: list approved events only (e.g. for listing detail).
  Future<List<BusinessEvent>> listApproved({String? businessId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('business_events').select().eq('status', _approved);
    if (businessId != null) q = q.eq('business_id', businessId);
    final list = await q.order('event_date', ascending: true).limit(_limit);
    return (list as List)
        .map((e) => BusinessEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: list events with optional status/business filter.
  Future<List<BusinessEvent>> listForAdmin({String? status, String? businessId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('business_events').select();
    if (status != null) q = q.eq('status', status);
    if (businessId != null) q = q.eq('business_id', businessId);
    final list = await q.order('event_date', ascending: true).limit(_limit);
    return (list as List)
        .map((e) => BusinessEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: update event status (e.g. approve/reject).
  /// Note: business_events may not have approved_at/approved_by; only status is required.
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    await client.from('business_events').update(data).eq('id', id);
  }

  /// Manager/admin: insert a new event (status defaults to pending per cheatsheet).
  Future<void> insert({
    required String businessId,
    required String title,
    required DateTime eventDate,
    String? description,
    DateTime? endDate,
    String? location,
    String? imageUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    final id =
        'e-${DateTime.now().millisecondsSinceEpoch}-${title.hashCode.abs()}';
    await client.from('business_events').insert({
      'id': id,
      'business_id': businessId,
      'title': title,
      'event_date': eventDate.toUtc().toIso8601String(),
      'description': description,
      'end_date': endDate?.toUtc().toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'status': 'pending',
    });
  }
}
