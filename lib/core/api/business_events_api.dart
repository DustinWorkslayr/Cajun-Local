import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_events_api.g.dart';

class BusinessEventsApi {
  BusinessEventsApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listEvents({
    String? businessId,
    String? status = 'approved',
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/business-events/',
        queryParameters: {
          if (businessId != null) 'business_id': businessId,
          if (status != null) 'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business events');
    }
  }

  Future<Map<String, dynamic>> getEventById(String id) async {
    try {
      final response = await _client.dio.get('/business-events/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business event');
    }
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/business-events/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business event');
    }
  }

  Future<Map<String, dynamic>> updateEventStatus(String id, String status) async {
    try {
      final response = await _client.dio.patch('/business-events/$id/status', queryParameters: {'status': status});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update event status');
    }
  }

  Future<Map<String, dynamic>> rsvpToEvent(String id, String status) async {
    try {
      final response = await _client.dio.post('/business-events/$id/rsvp', data: {'status': status});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to RSVP to event');
    }
  }
}

@riverpod
BusinessEventsApi businessEventsApi(BusinessEventsApiRef ref) {
  return BusinessEventsApi(ApiClient.instance);
}
