import 'package:my_app/core/data/models/business_manager_entry.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business managers (backend-cheatsheet §2). Admin or existing manager can insert.
/// RLS: admin OR manager can SELECT/INSERT/DELETE for their business (see 20260303130000).
class BusinessManagersRepository {
  BusinessManagersRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List users with access to this business (callable by admin or manager).
  Future<List<BusinessManagerEntry>> listManagersForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client.rpc(
      'list_business_managers',
      params: {'p_business_id': businessId},
    );
    if (list == null || list is! List) return [];
    return (list)
        .map((e) => BusinessManagerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Resolve user id by email for adding team access (callable by admin or manager).
  Future<String?> lookupUserByEmail(String businessId, String email) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.rpc(
      'lookup_user_id_by_email',
      params: {'p_business_id': businessId, 'p_email': email.trim()},
    );
    if (res == null) return null;
    return res is String ? res : res.toString();
  }

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

  /// Add a user as manager (admin or existing manager; RLS enforces).
  Future<void> insert(String businessId, String userId, {String role = 'owner'}) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_managers').insert({
      'business_id': businessId,
      'user_id': userId,
      'role': role,
    });
  }

  /// Remove a manager from a business (admin or existing manager; RLS enforces).
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
