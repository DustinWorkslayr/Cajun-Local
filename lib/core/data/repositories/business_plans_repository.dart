import 'package:my_app/core/data/models/business_plan.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business subscription plans (pricing-and-ads-cheatsheet §2.1). Public SELECT; admin-only write.
class BusinessPlansRepository {
  BusinessPlansRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<BusinessPlan>> list() async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_plans')
        .select()
        .order('sort_order')
        .order('name');
    return (list as List<dynamic>)
        .map((e) => BusinessPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BusinessPlan?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('business_plans').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return BusinessPlan.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> insert(BusinessPlan plan) async {
    final client = _client;
    if (client == null) return;
    final data = plan.toJson()
      ..remove('id');
    await client.from('business_plans').insert(data);
  }

  Future<void> update(BusinessPlan plan) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_plans').update(plan.toJson()).eq('id', plan.id);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_plans').delete().eq('id', id);
  }
}
