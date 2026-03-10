import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notification_preferences_api.g.dart';

class UserNotificationPreferencesApi {
  UserNotificationPreferencesApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> read() async {
    try {
      final response = await _client.dio.get('/user-notification-preferences/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return {};
      throw Exception(e.response?.data?['detail'] ?? 'Failed to read notification preferences');
    }
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/user-notification-preferences/me', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update notification preferences');
    }
  }
}

@riverpod
UserNotificationPreferencesApi userNotificationPreferencesApi(UserNotificationPreferencesApiRef ref) {
  return UserNotificationPreferencesApi(ApiClient.instance);
}
