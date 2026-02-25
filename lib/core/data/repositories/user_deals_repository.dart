import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/models/user_deal.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-deals (backend-cheatsheet §1). RLS: own SELECT/INSERT; UPDATE admin only.
/// Tracks which deals the user has claimed. Redemption (used_at) is admin or future redeem_deal().
class UserDealsRepository {
  UserDealsRepository({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List deals claimed by [userId] (or current user if null). Returns [] when no user. Throws when backend not configured.
  Future<List<UserDeal>> listForUser(String? userId) async {
    final uid = userId ?? _auth.currentUserId;
    if (uid == null) return [];
    final client = _client;
    if (client == null) {
      throw StateError(ListingDataSource.kNotConfiguredMessage);
    }
    final list = await client
        .from('user_deals')
        .select()
        .eq('user_id', uid)
        .order('claimed_at', ascending: false);
    return (list as List)
        .map((e) => UserDeal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deal IDs claimed by the current user. Convenience for UI.
  Future<Set<String>> getClaimedDealIds(String? userId) async {
    final list = await listForUser(userId);
    return list.map((e) => e.dealId).toSet();
  }

  /// Claim a deal for [userId] (or current user if null). RLS requires user_id = auth.uid().
  /// Idempotent: unique constraint prevents duplicate. Throws when backend not configured.
  Future<void> claim(String? userId, String dealId) async {
    final uid = userId ?? _auth.currentUserId;
    if (uid == null) return;
    final client = _client;
    if (client == null) {
      throw StateError(ListingDataSource.kNotConfiguredMessage);
    }
    await client.from('user_deals').insert({
      'user_id': uid,
      'deal_id': dealId,
      'claimed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Whether the current user has claimed this deal.
  Future<bool> hasClaimed(String? userId, String dealId) async {
    final uid = userId ?? _auth.currentUserId;
    final ids = await getClaimedDealIds(uid);
    return ids.contains(dealId);
  }

  /// Admin: list all claimed deals (user_deals). RLS: admin can SELECT all.
  Future<List<UserDeal>> listForAdmin() async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('user_deals')
        .select()
        .order('claimed_at', ascending: false)
        .limit(500);
    return (list as List)
        .map((e) => UserDeal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: set used_at on a user_deal (mark as redeemed). RLS: admin only.
  Future<void> setUsedAt(String userId, String dealId) async {
    final client = _client;
    if (client == null) return;
    await client.from('user_deals').update({
      'used_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', userId).eq('deal_id', dealId);
  }
}
