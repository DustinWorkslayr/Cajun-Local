import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_subscriptions_api.g.dart';

class BusinessSubscriptionsApi {
  BusinessSubscriptionsApi(this._client);
  final ApiClient _client;

  /// Fetch subscription for a business.
  Future<Map<String, dynamic>> getByBusinessId(String businessId) async {
    try {
      final response = await _client.dio.get('/business-subscriptions/business/$businessId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('not_found');
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get subscription');
    }
  }

  /// Admin: assign or change plan.
  Future<void> assignPlan(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/business-subscriptions/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to assign plan');
    }
  }

  /// Admin: remove subscription.
  Future<void> removeSubscription(String businessId) async {
    try {
      await _client.dio.delete('/business-subscriptions/business/$businessId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to remove subscription');
    }
  }

  /// Get active tiers for multiple businesses.
  Future<Map<String, String>> getActiveTiers(List<String> businessIds) async {
    try {
      final response = await _client.dio.get(
        '/business-subscriptions/active-tiers',
        queryParameters: {'business_ids': businessIds},
      );
      final data = response.data as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as String));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get active tiers');
    }
  }
}

@riverpod
BusinessSubscriptionsApi businessSubscriptionsApi(BusinessSubscriptionsApiRef ref) {
  return BusinessSubscriptionsApi(ApiClient.instance);
}
