import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/notifications_api.dart';
import 'package:my_app/core/data/models/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_repository.g.dart';

/// Per-user notifications (backend-cheatsheet §1). RLS: own SELECT/UPDATE; admin INSERT/DELETE.
class NotificationsRepository {
  NotificationsRepository({NotificationsApi? api}) : _api = api ?? NotificationsApi(ApiClient.instance);
  final NotificationsApi _api;

  /// List notifications for the current user (own only).
  Future<List<AppNotification>> listForUser(String userId, {String? typeFilter, int limit = 50, int offset = 0}) async {
    return _api.list(type: typeFilter, skip: offset, limit: limit);
  }

  /// Unread count for badge.
  Future<int> unreadCount(String userId) async {
    return _api.unreadCount();
  }

  /// Mark as read (own only via RLS).
  Future<void> markAsRead(String id) async {
    await _api.markAsRead(id);
  }

  /// Mark all notifications as read for the user.
  Future<void> markAllAsRead(String userId) async {
    await _api.markAllAsRead();
  }

  /// Delete one notification (own only via RLS).
  Future<void> deleteForUser(String id) async {
    await _api.delete(id);
  }

  /// Admin: list all notifications.
  Future<List<AppNotification>> listForAdmin({String? userId}) async {
    return _api.listAdmin(userId: userId);
  }

  /// Admin: send a notification to a user.
  Future<void> insert({
    required String userId,
    required String title,
    String? body,
    String? type,
    String? actionUrl,
  }) async {
    await _api.create({'user_id': userId, 'title': title, 'body': body, 'type': type, 'action_url': actionUrl});
  }

  /// Admin: delete a notification.
  Future<void> delete(String id) async {
    await _api.delete(id);
  }
}

@riverpod
NotificationsRepository notificationsRepository(NotificationsRepositoryRef ref) {
  return NotificationsRepository(api: ref.watch(notificationsApiProvider));
}
