import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/form_submission.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_submissions_api.g.dart';

class FormSubmissionsApi {
  FormSubmissionsApi(this._client);
  final ApiClient _client;

  /// Fetch submissions for a business.
  Future<List<FormSubmission>> listForBusiness(String businessId, {int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/form-submissions/business/$businessId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => FormSubmission.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list submissions');
    }
  }

  /// Create a submission.
  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/form-submissions/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to submit form');
    }
  }

  /// Update a submission (Admin/Manager).
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/form-submissions/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update submission');
    }
  }

  /// Admin: list all submissions.
  Future<List<FormSubmission>> listAll({String? businessId, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/form-submissions/',
        queryParameters: {if (businessId != null) 'business_id': businessId, 'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => FormSubmission.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list all submissions');
    }
  }

  /// Get unread count.
  Future<int> getUnreadCount(List<String> businessIds) async {
    try {
      final response = await _client.dio.get(
        '/form-submissions/unread-count',
        queryParameters: {'business_ids': businessIds},
      );
      return response.data as int;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get unread count');
    }
  }

  /// Admin: delete submission.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/form-submissions/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete submission');
    }
  }
}

@riverpod
FormSubmissionsApi formSubmissionsApi(FormSubmissionsApiRef ref) {
  return FormSubmissionsApi(ApiClient.instance);
}
