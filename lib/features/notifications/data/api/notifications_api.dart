import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/notifications/data/models/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_api.g.dart';

class NotificationsApi {
  NotificationsApi(this._client);
  final ApiClient _client;

  /// Fetch notifications for current user.
  Future<List<AppNotification>> list({String? type, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/notifications/',
        queryParameters: {if (type != null) 'type': type, 'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list notifications');
    }
  }

  /// Get unread count.
  Future<int> unreadCount() async {
    try {
      final response = await _client.dio.get('/notifications/unread-count');
      return response.data['count'] as int;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get unread count');
    }
  }

  /// Mark as read.
  Future<void> markAsRead(String id) async {
    try {
      await _client.dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to mark notification as read');
    }
  }

  /// Mark all as read.
  Future<void> markAllAsRead() async {
    try {
      await _client.dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to mark all as read');
    }
  }

  /// Delete notification.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete notification');
    }
  }

  /// Admin: list notifications.
  Future<List<AppNotification>> listAdmin({String? userId, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/notifications/admin',
        queryParameters: {if (userId != null) 'user_id': userId, 'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list notifications (admin)');
    }
  }

  /// Admin: create notification.
  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/notifications/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create notification');
    }
  }
}

@riverpod
NotificationsApi notificationsApi(NotificationsApiRef ref) {
  return NotificationsApi(ApiClient.instance);
}
