import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business managers (backend-cheatsheet §2). Admin or existing manager can insert.
/// RLS: admin OR manager can SELECT (own rows).
class BusinessManagersRepository {
  BusinessManagersRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// One user_id to notify for a business (first manager). Admin use for approval emails.
  Future<String?> getFirstManagerUserId(String businessId) async {
    final client = _client;
    if (client == null) return null;
    final list = await client
        .from('business_managers')
        .select('user_id')
        .eq('business_id', businessId)
        .limit(1);
    final first = list.firstOrNull;
    if (first == null) return null;
    return first['user_id'] as String?;
  }

  /// List business IDs that the user manages (RLS: user sees own rows).
  Future<List<String>> listBusinessIdsForUser(String userId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_managers')
        .select('business_id')
        .eq('user_id', userId);
    return (list as List)
        .map((e) => (e as Map<String, dynamic>)['business_id'] as String)
        .toList();
  }

  /// Admin: add a manager to a business (e.g. after claim approval).
  Future<void> insert(String businessId, String userId, {String role = 'owner'}) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_managers').insert({
      'business_id': businessId,
      'user_id': userId,
      'role': role,
    });
  }

  /// Admin: remove a manager from a business.
  Future<void> delete(String businessId, String userId) async {
    final client = _client;
    if (client == null) return;
    await client
        .from('business_managers')
        .delete()
        .eq('business_id', businessId)
        .eq('user_id', userId);
  }
}
