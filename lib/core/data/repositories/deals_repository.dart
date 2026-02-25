import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public read: deals status = approved (§7).
class DealsRepository {
  DealsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _approved = 'approved';
  static const _limit = 1000;

  Future<List<Deal>> listApproved({
    bool activeOnly = false,
    String? businessId,
  }) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('deals').select().eq('status', _approved);
    if (businessId != null) q = q.eq('business_id', businessId);
    if (activeOnly) q = q.eq('is_active', true);
    final list = await q.limit(_limit);
    return (list as List)
        .map((e) => Deal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: list deals with optional status/business filter.
  Future<List<Deal>> listForAdmin({String? status, String? businessId}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('deals').select();
    if (status != null) q = q.eq('status', status);
    if (businessId != null) q = q.eq('business_id', businessId);
    final list = await q.order('title').limit(_limit);
    return (list as List)
        .map((e) => Deal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get approved deal by id (for user-facing screens e.g. My deals). Returns null if not found or not approved.
  Future<Deal?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('deals').select().eq('id', id).eq('status', _approved).maybeSingle();
    if (res == null) return null;
    return Deal.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: get deal by id (any status).
  Future<Deal?> getByIdForAdmin(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('deals').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Deal.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: update status. When approving, pass [approvedBy].
  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == _approved && approvedBy != null) {
      data['approved_at'] = DateTime.now().toUtc().toIso8601String();
      data['approved_by'] = approvedBy;
    }
    await client.from('deals').update(data).eq('id', id);
  }

  /// Manager: list all deals for a business (any status). RLS: manager can read own business.
  Future<List<Deal>> listForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('deals').select().eq('business_id', businessId).order('title').limit(_limit);
    return (list as List).map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Manager: delete a deal. RLS must allow manager to delete own business deals.
  Future<void> deleteForManager(String dealId) async {
    final client = _client;
    if (client == null) return;
    await client.from('deals').delete().eq('id', dealId);
  }

  /// Manager/admin: insert a new deal (status defaults to pending per cheatsheet).
  /// [startDate]/[endDate] supported for Local+ and above (scheduling).
  Future<void> insert({
    required String businessId,
    required String title,
    String dealType = 'other',
    String? description,
    bool isActive = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = 'd-${DateTime.now().millisecondsSinceEpoch}-${title.hashCode.abs()}';
    final data = <String, dynamic>{
      'id': id,
      'business_id': businessId,
      'title': title,
      'deal_type': dealType,
      'status': 'pending',
      'description': description,
      'is_active': isActive,
    };
    if (startDate != null) data['start_date'] = startDate.toUtc().toIso8601String();
    if (endDate != null) data['end_date'] = endDate.toUtc().toIso8601String();
    await client.from('deals').insert(data);
  }

  /// Count of deals for [businessId] that are active (is_active = true). Any status.
  Future<int> countActiveForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return 0;
    final list = await client
        .from('deals')
        .select('id')
        .eq('business_id', businessId)
        .eq('is_active', true)
        .limit(1000);
    return (list as List).length;
  }
}
