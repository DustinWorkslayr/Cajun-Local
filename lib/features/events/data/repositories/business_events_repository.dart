import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/events/data/api/business_events_api.dart';
import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_events_repository.g.dart';

/// business_events: manager/admin CRUD; public read when status = approved (§7).
class BusinessEventsRepository {
  BusinessEventsRepository({BusinessEventsApi? api}) : _api = api ?? BusinessEventsApi(ApiClient.instance);

  final BusinessEventsApi _api;

  static const _approved = 'approved';
  static const _limit = 1000;

  /// List events for a business (manager sees all statuses).
  Future<List<BusinessEvent>> listForBusiness(String businessId) async {
    final list = await _api.listEvents(businessId: businessId, status: null, limit: _limit);
    return list.map((e) => BusinessEvent.fromJson(e)).toList();
  }

  /// Get a single event by id.
  Future<BusinessEvent?> getById(String eventId) async {
    try {
      final res = await _api.getEventById(eventId);
      return BusinessEvent.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Public: list approved events only.
  Future<List<BusinessEvent>> listApproved({String? businessId}) async {
    final list = await _api.listEvents(businessId: businessId, status: _approved, limit: _limit);
    return list.map((e) => BusinessEvent.fromJson(e)).toList();
  }

  /// Admin: list events with optional status/business filter.
  Future<List<BusinessEvent>> listForAdmin({String? status, String? businessId}) async {
    final list = await _api.listEvents(status: status, businessId: businessId, limit: _limit);
    return list.map((e) => BusinessEvent.fromJson(e)).toList();
  }

  /// Admin: update event status (e.g. approve/reject).
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    await _api.updateEventStatus(id, status);
  }

  /// Manager/admin: insert a new event.
  Future<void> insert({
    required String businessId,
    required String title,
    required DateTime eventDate,
    String? description,
    DateTime? endDate,
    String? location,
    String? imageUrl,
  }) async {
    await _api.createEvent({
      'business_id': businessId,
      'title': title,
      'event_date': eventDate.toUtc().toIso8601String(),
      'description': description,
      'end_date': endDate?.toUtc().toIso8601String(),
      'location': location,
      'image_url': imageUrl,
    });
  }
}

@riverpod
BusinessEventsRepository businessEventsRepository(BusinessEventsRepositoryRef ref) {
  return BusinessEventsRepository(api: ref.watch(businessEventsApiProvider));
}
