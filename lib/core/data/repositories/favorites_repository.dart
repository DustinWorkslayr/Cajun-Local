import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Favorites (backend-cheatsheet §1). RLS: own SELECT/INSERT/DELETE; no UPDATE.
class FavoritesRepository {
  FavoritesRepository({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List business IDs favorited by the current user. Returns [] when not signed in or not configured.
  Future<List<String>> list() async {
    final client = _client;
    final userId = _auth.currentUserId;
    if (client == null || userId == null) return [];
    final list = await client
        .from('favorites')
        .select('business_id')
        .eq('user_id', userId);
    return (list as List)
        .map((e) => (e as Map<String, dynamic>)['business_id'] as String)
        .toList();
  }

  /// Add a favorite for the current user. No-op when not signed in or not configured.
  Future<void> add(String businessId) async {
    final client = _client;
    final userId = _auth.currentUserId;
    if (client == null || userId == null) return;
    await client.from('favorites').insert({
      'user_id': userId,
      'business_id': businessId,
    });
  }

  /// Remove a favorite for the current user. No-op when not configured.
  Future<void> remove(String businessId) async {
    final client = _client;
    final userId = _auth.currentUserId;
    if (client == null || userId == null) return;
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('business_id', businessId);
  }

  /// Total number of users who favorited this business. Returns 0 when not configured or RPC missing.
  Future<int> getCountForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return 0;
    try {
      final res = await client.rpc('get_favorites_count', params: {'business_id': businessId});
      if (res == null) return 0;
      final n = res is int ? res : int.tryParse(res.toString());
      return n ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Favorites count per business. Uses get_favorites_count in parallel. Missing/errors yield 0.
  Future<Map<String, int>> getCountsForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    final list = await Future.wait(
      businessIds.map((id) => getCountForBusiness(id).then((c) => MapEntry(id, c))),
    );
    return Map.fromEntries(list);
  }
}
