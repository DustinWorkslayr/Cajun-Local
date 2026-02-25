import 'package:my_app/core/data/models/notification_banner.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationBannersRepository {
  NotificationBannersRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<NotificationBanner>> list() async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('notification_banners').select().order('created_at', ascending: false);
    return (list as List).map((e) => NotificationBanner.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns banners that are active and currently within their date window (or unbounded if null).
  /// Used for user-facing home/shell display.
  Future<List<NotificationBanner>> listActive() async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('notification_banners')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    final now = DateTime.now();
    return (list as List)
        .map((e) => NotificationBanner.fromJson(e as Map<String, dynamic>))
        .where((b) {
          if (b.startDate != null && b.startDate!.isAfter(now)) return false;
          if (b.endDate != null && !b.endDate!.isAfter(now)) return false;
          return true;
        })
        .toList();
  }

  Future<NotificationBanner?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('notification_banners').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return NotificationBanner.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('notification_banners').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) return;
    await client.from('notification_banners').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('notification_banners').delete().eq('id', id);
  }
}
