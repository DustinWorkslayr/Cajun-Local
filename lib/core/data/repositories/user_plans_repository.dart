import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User subscription plans (pricing-and-ads-cheatsheet §2.3). Public SELECT; admin-only write.
class UserPlansRepository {
  UserPlansRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<UserPlan>> list() async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('user_plans')
        .select()
        .order('sort_order')
        .order('name');
    return (list as List<dynamic>)
        .map((e) => UserPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<UserPlan?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('user_plans').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return UserPlan.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> insert(UserPlan plan) async {
    final client = _client;
    if (client == null) return;
    final data = plan.toJson()
      ..remove('id');
    await client.from('user_plans').insert(data);
  }

  Future<void> update(UserPlan plan) async {
    final client = _client;
    if (client == null) return;
    await client.from('user_plans').update(plan.toJson()).eq('id', plan.id);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('user_plans').delete().eq('id', id);
  }
}
