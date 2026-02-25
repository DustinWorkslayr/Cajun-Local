import 'package:my_app/core/data/models/user_subscription.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// user_subscriptions: one per user (UNIQUE user_id). Admin-only write (pricing-and-ads-cheatsheet §2.4).
class UserSubscriptionsRepository {
  UserSubscriptionsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Get the active subscription for a user, if any.
  Future<UserSubscription?> getByUserId(String userId) async {
    final client = _client;
    if (client == null) return null;
    final res = await client
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return UserSubscription.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: assign or change plan for a user. Upserts one row per user.
  Future<void> setPlanForUser(String userId, String planId) async {
    final client = _client;
    if (client == null) return;
    final existing = await getByUserId(userId);
    final now = DateTime.now().toUtc();
    if (existing != null) {
      await client.from('user_subscriptions').update({
        'plan_id': planId,
        'status': 'active',
        'current_period_start': now.toIso8601String(),
        'current_period_end': now.add(const Duration(days: 30)).toIso8601String(),
      }).eq('user_id', userId);
    } else {
      await client.from('user_subscriptions').insert({
        'user_id': userId,
        'plan_id': planId,
        'status': 'active',
        'billing_interval': 'monthly',
        'current_period_start': now.toIso8601String(),
        'current_period_end': now.add(const Duration(days: 30)).toIso8601String(),
      });
    }
  }

  /// Admin: remove subscription for a user (downgrade to no plan).
  Future<void> deleteByUserId(String userId) async {
    final client = _client;
    if (client == null) return;
    await client.from('user_subscriptions').delete().eq('user_id', userId);
  }
}
