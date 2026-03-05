import 'package:my_app/core/data/models/app_notification.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-user notifications (backend-cheatsheet §1). RLS: own SELECT/UPDATE; admin INSERT/DELETE.
class NotificationsRepository {
  NotificationsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List notifications for the current user (own only). Optional [typeFilter]. Paginated via [limit] and [offset].
  Future<List<AppNotification>> listForUser(
    String userId, {
    String? typeFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('notifications').select().eq('user_id', userId);
    if (typeFilter != null && typeFilter.isNotEmpty) {
      q = q.eq('type', typeFilter);
    }
    final list = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (list as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Unread count for badge.
  Future<int> unreadCount(String userId) async {
    final client = _client;
    if (client == null) return 0;
    final list = await client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (list as List).length;
  }

  /// Mark as read (own only via RLS).
  Future<void> markAsRead(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Mark all notifications as read for the user.
  Future<void> markAllAsRead(String userId) async {
    final client = _client;
    if (client == null) return;
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Delete one notification (own only via RLS). No-op if RLS denies.
  Future<void> deleteForUser(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('notifications').delete().eq('id', id);
  }

  /// Admin: list all notifications (optional user filter).
  Future<List<AppNotification>> listForAdmin({String? userId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('notifications').select();
    if (userId != null) q = q.eq('user_id', userId);
    final list = await q.order('created_at', ascending: false).limit(500);
    return (list as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: send a notification to a user.
  Future<void> insert({
    required String userId,
    required String title,
    String? body,
    String? type,
    String? actionUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = 'n-${DateTime.now().millisecondsSinceEpoch}-${userId.hashCode.abs()}';
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'is_read': false,
    };
    if (body != null && body.isNotEmpty) map['body'] = body;
    if (type != null && type.isNotEmpty) map['type'] = type;
    if (actionUrl != null && actionUrl.isNotEmpty) map['action_url'] = actionUrl;
    await client.from('notifications').insert(map);
  }

  /// Admin: delete a notification.
  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('notifications').delete().eq('id', id);
  }
}
