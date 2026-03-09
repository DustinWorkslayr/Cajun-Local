import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/event_rsvp.dart';
import 'package:my_app/core/data/repositories/event_rsvps_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_rsvps_api.g.dart';

class EventRsvpsApi {
  EventRsvpsApi(this._client);
  final ApiClient _client;

  Future<List<EventRsvp>> listMyRsvps({int skip = 0, int limit = 2000}) async {
    try {
      final response = await _client.dio.get('/event-rsvps/my-rsvps', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.map((json) => EventRsvp.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list my RSVPs');
    }
  }

  Future<EventRsvp?> getMyRsvpForEvent(String eventId) async {
    try {
      final response = await _client.dio.get('/event-rsvps/event/$eventId/my-rsvp');
      return EventRsvp.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get my RSVP for event');
    }
  }

  Future<List<EventRsvp>> listByEvent(String eventId, {int skip = 0, int limit = 2000}) async {
    try {
      final response = await _client.dio.get(
        '/event-rsvps/event/$eventId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => EventRsvp.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list RSVPs for event');
    }
  }

  Future<EventRsvpCounts> getCountsForEvent(String eventId) async {
    try {
      final response = await _client.dio.get('/event-rsvps/event/$eventId/counts');
      final data = response.data as Map<String, dynamic>;
      return EventRsvpCounts(
        going: data['going'] as int? ?? 0,
        interested: data['interested'] as int? ?? 0,
        notGoing: data['not_going'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get RSVP counts for event');
    }
  }

  Future<void> upsert(String eventId, String status) async {
    try {
      await _client.dio.put('/event-rsvps/event/$eventId/my-rsvp', data: {'status': status});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to upsert RSVP');
    }
  }

  Future<void> delete(String eventId) async {
    try {
      await _client.dio.delete('/event-rsvps/event/$eventId/my-rsvp');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete RSVP');
    }
  }
}

@riverpod
EventRsvpsApi eventRsvpsApi(EventRsvpsApiRef ref) {
  return EventRsvpsApi(ApiClient.instance);
}
