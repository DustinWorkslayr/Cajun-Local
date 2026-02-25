import 'package:my_app/core/data/models/business_claim.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business ownership claims (backend-cheatsheet §2). Admin can list and update status.
class BusinessClaimsRepository {
  BusinessClaimsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 500;

  Future<List<BusinessClaim>> listForAdmin({String? status}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('business_claims').select();
    if (status != null) q = q.eq('status', status);
    final list = await q.order('created_at', ascending: false).limit(_limit);
    return (list as List).map((e) => BusinessClaim.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BusinessClaim?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('business_claims').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return BusinessClaim.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStatus(String id, String status) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_claims').update({'status': status}).eq('id', id);
  }

  /// User submits a claim (RLS: user_id = auth.uid()). Returns new claim id or null on failure.
  Future<String?> insert({
    required String userId,
    required String businessId,
    required String claimDetails,
  }) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('business_claims').insert({
      'user_id': userId,
      'business_id': businessId,
      'claim_details': claimDetails,
      'status': 'pending',
    }).select('id').maybeSingle();
    if (res == null) return null;
    return res['id'] as String?;
  }

  /// Get the current user's claim for this business (pending or approved). Used to show "Under review" or hide claim CTA.
  Future<BusinessClaim?> getForUserAndBusiness(String userId, String businessId) async {
    final client = _client;
    if (client == null) return null;
    final list = await client
        .from('business_claims')
        .select()
        .eq('user_id', userId)
        .eq('business_id', businessId)
        .inFilter('status', ['pending', 'approved'])
        .order('created_at', ascending: false)
        .limit(1);
    final items = list as List;
    if (items.isEmpty) return null;
    return BusinessClaim.fromJson(Map<String, dynamic>.from(items.first as Map));
  }
}
