import 'package:my_app/core/data/models/ad_package.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ad packages (pricing-and-ads-cheatsheet §2.5). Public SELECT; admin-only write.
class AdPackagesRepository {
  AdPackagesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<AdPackage>> list({bool activeOnly = false}) async {
    final client = _client;
    if (client == null) return [];
    var query = client.from('ad_packages').select();
    if (activeOnly) query = query.eq('is_active', true);
    final list = await query.order('sort_order').order('name');
    return (list as List<dynamic>)
        .map((e) => AdPackage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdPackage?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('ad_packages').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return AdPackage.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> insert(AdPackage pkg) async {
    final client = _client;
    if (client == null) return;
    final data = pkg.toJson()..remove('id');
    await client.from('ad_packages').insert(data);
  }

  Future<void> update(AdPackage pkg) async {
    final client = _client;
    if (client == null) return;
    await client.from('ad_packages').update(pkg.toJson()).eq('id', pkg.id);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('ad_packages').delete().eq('id', id);
  }
}
