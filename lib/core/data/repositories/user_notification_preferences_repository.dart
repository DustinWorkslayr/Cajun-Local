import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-user notification preference flags. RLS: own SELECT/INSERT/UPDATE.
/// Tolerates missing table (e.g. migration not applied): returns/skips without throwing.
class UserNotificationPreferencesRepository {
  UserNotificationPreferencesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Get preferences for the current user. Returns defaults if no row exists or table is missing.
  Future<UserNotificationPreferences> get(String userId) async {
    final client = _client;
    if (client == null) return UserNotificationPreferences.defaults();
    try {
      final res = await client
          .from('user_notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return UserNotificationPreferences.defaults();
      return UserNotificationPreferences.fromJson(Map<String, dynamic>.from(res));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || (e.message.contains('schema cache') && e.message.contains('user_notification_preferences'))) {
        return UserNotificationPreferences.defaults();
      }
      rethrow;
    }
  }

  /// Save preferences (upsert). No-op if table is missing.
  Future<void> save(String userId, UserNotificationPreferences prefs) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('user_notification_preferences').upsert({
        'user_id': userId,
        'deals_enabled': prefs.dealsEnabled,
        'listings_enabled': prefs.listingsEnabled,
        'reminders_enabled': prefs.remindersEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || (e.message.contains('schema cache') && e.message.contains('user_notification_preferences'))) {
        return;
      }
      rethrow;
    }
  }

  /// Admin: save preferences for any user (upsert). RLS: admin can INSERT/UPDATE.
  Future<void> saveForAdmin(String userId, UserNotificationPreferences prefs) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('user_notification_preferences').upsert({
        'user_id': userId,
        'deals_enabled': prefs.dealsEnabled,
        'listings_enabled': prefs.listingsEnabled,
        'reminders_enabled': prefs.remindersEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || (e.message.contains('schema cache') && e.message.contains('user_notification_preferences'))) {
        return;
      }
      rethrow;
    }
  }
}

class UserNotificationPreferences {
  const UserNotificationPreferences({
    required this.dealsEnabled,
    required this.listingsEnabled,
    required this.remindersEnabled,
  });

  final bool dealsEnabled;
  final bool listingsEnabled;
  final bool remindersEnabled;

  static UserNotificationPreferences defaults() => const UserNotificationPreferences(
        dealsEnabled: true,
        listingsEnabled: true,
        remindersEnabled: false,
      );

  factory UserNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return UserNotificationPreferences(
      dealsEnabled: json['deals_enabled'] as bool? ?? true,
      listingsEnabled: json['listings_enabled'] as bool? ?? true,
      remindersEnabled: json['reminders_enabled'] as bool? ?? false,
    );
  }
}
