import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/data/models/user_subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_subscriptions_api.g.dart';

class UserSubscriptionsApi {
  UserSubscriptionsApi(this._client);
  final ApiClient _client;

  Future<UserSubscription?> getByUserId(String userId) async {
    try {
      final response = await _client.dio.get('/user-subscriptions/user/$userId');
      if (response.data == null) return null;
      return UserSubscription.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get user subscription');
    }
  }

  Future<void> setPlanForUser(String userId, String planId) async {
    try {
      await _client.dio.post('/user-subscriptions/user/$userId/set-plan', queryParameters: {'plan_id': planId});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to set plan for user');
    }
  }

  Future<void> deleteByUserId(String userId) async {
    try {
      await _client.dio.delete('/user-subscriptions/user/$userId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete user subscription');
    }
  }
}

@riverpod
UserSubscriptionsApi userSubscriptionsApi(UserSubscriptionsApiRef ref) {
  return UserSubscriptionsApi(ApiClient.instance);
}
