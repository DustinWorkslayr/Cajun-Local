import 'package:my_app/core/data/models/business_link.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public read: business_links (§7).
class BusinessLinksRepository {
  BusinessLinksRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<BusinessLink>> getForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_links')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return (list as List)
        .map((e) => BusinessLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manager/admin: insert a link. Returns new id.
  Future<String> insert({
    required String businessId,
    required String url,
    String? label,
    int? sortOrder,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final id = 'bl-${DateTime.now().millisecondsSinceEpoch}-${url.hashCode.abs()}';
    await client.from('business_links').insert({
      'id': id,
      'business_id': businessId,
      'url': url,
      'label': label,
      'sort_order': sortOrder,
    });
    return id;
  }

  /// Manager/admin: update label, url, sort_order.
  Future<void> update(String id, {String? url, String? label, int? sortOrder}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (url != null) data['url'] = url;
    if (label != null) data['label'] = label;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await client.from('business_links').update(data).eq('id', id);
  }

  /// Manager/admin: delete a link.
  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_links').delete().eq('id', id);
  }
}
