import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/data/models/notification_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_banners_api.g.dart';

class NotificationBannersApi {
  NotificationBannersApi(this._client);
  final ApiClient _client;

  /// Fetch notification banners.
  Future<List<NotificationBanner>> list({bool activeOnly = false, int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/notification-banners/',
        queryParameters: {'active_only': activeOnly, 'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => NotificationBanner.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list notification banners');
    }
  }

  /// Get banner by ID.
  Future<NotificationBanner?> getById(String id) async {
    try {
      final response = await _client.dio.get('/notification-banners/$id');
      return NotificationBanner.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get notification banner');
    }
  }

  /// Admin: insert notification banner.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('/notification-banners/', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create notification banner');
    }
  }

  /// Admin: update notification banner.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('/notification-banners/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update notification banner');
    }
  }

  /// Admin: delete notification banner.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/notification-banners/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete notification banner');
    }
  }
}

@riverpod
NotificationBannersApi notificationBannersApi(NotificationBannersApiRef ref) {
  return NotificationBannersApi(ApiClient.instance);
}
