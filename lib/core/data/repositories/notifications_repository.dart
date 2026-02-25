import 'package:my_app/core/data/models/app_notification.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-user notifications (backend-cheatsheet §1). RLS: own SELECT/UPDATE; admin INSERT/DELETE.
class NotificationsRepository {
  NotificationsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List notifications for the current user (own only).
  Future<List<AppNotification>> listForUser(String userId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
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
    String? type,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = 'n-${DateTime.now().millisecondsSinceEpoch}-${userId.hashCode.abs()}';
    await client.from('notifications').insert({
      'id': id,
      'user_id': userId,
      'title': title,
      'type': type,
      'is_read': false,
    });
  }

  /// Admin: delete a notification.
  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('notifications').delete().eq('id', id);
  }
}
