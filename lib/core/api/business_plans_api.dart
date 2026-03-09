import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/business_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_plans_api.g.dart';

class BusinessPlansApi {
  BusinessPlansApi(this._client);
  final ApiClient _client;

  /// Fetch all business plans.
  Future<List<BusinessPlan>> list() async {
    try {
      final response = await _client.dio.get('/business-plans/');
      final data = response.data as List;
      return data.map((json) => BusinessPlan.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business plans');
    }
  }

  /// Get business plan by ID.
  Future<BusinessPlan?> getById(String id) async {
    try {
      final response = await _client.dio.get('/business-plans/$id');
      return BusinessPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get business plan');
    }
  }

  /// Admin: insert business plan.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/business-plans/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create business plan');
    }
  }

  /// Admin: update business plan.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/business-plans/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update business plan');
    }
  }

  /// Admin: delete business plan.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/business-plans/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete business plan');
    }
  }
}

@riverpod
BusinessPlansApi businessPlansApi(BusinessPlansApiRef ref) {
  return BusinessPlansApi(ApiClient.instance);
}
