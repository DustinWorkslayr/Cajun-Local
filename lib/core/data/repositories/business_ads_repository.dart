import 'package:my_app/core/data/models/business_ad.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Business ads (pricing-and-ads-cheatsheet §2.6). Managers INSERT (draft); admin UPDATE/DELETE.
class BusinessAdsRepository {
  BusinessAdsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List ads for a business (managers see own; admin can use this too).
  Future<List<BusinessAd>> listByBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('business_ads')
        .select('*, ad_packages(name, placement)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return _mapList(list);
  }

  /// Admin: list all ads, optional status filter.
  Future<List<BusinessAd>> listAll({String? status}) async {
    final client = _client;
    if (client == null) return [];
    var query = client
        .from('business_ads')
        .select('*, ad_packages(name, placement)');
    if (status != null && status.isNotEmpty) query = query.eq('status', status);
    final list = await query.order('created_at', ascending: false);
    return _mapList(list);
  }

  List<BusinessAd> _mapList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) {
      final map = Map<String, dynamic>.from(e);
      final pkg = map['ad_packages'];
      if (pkg is Map) {
        map['package_name'] = pkg['name'];
        map['placement'] = pkg['placement'];
      }
      map.remove('ad_packages');
      return BusinessAd.fromJson(map);
    }).toList();
  }

  Future<BusinessAd?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client
        .from('business_ads')
        .select('*, ad_packages(name, placement)')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    final map = Map<String, dynamic>.from(res);
    final pkg = map['ad_packages'];
    if (pkg is Map) {
      map['package_name'] = pkg['name'];
      map['placement'] = pkg['placement'];
    }
    map.remove('ad_packages');
    return BusinessAd.fromJson(map);
  }

  /// Manager: insert draft ad. Only allowed fields.
  Future<BusinessAd?> insertDraft({
    required String businessId,
    required String packageId,
    String? headline,
    String? imageUrl,
    String? targetUrl,
  }) async {
    final client = _client;
    if (client == null) return null;
    final data = <String, dynamic>{
      'business_id': businessId,
      'package_id': packageId,
      'status': 'draft',
      'headline': headline,
      'image_url': imageUrl,
      'target_url': targetUrl,
    };
    final res = await client.from('business_ads').insert(data).select().single();
    return BusinessAd.fromJson(Map<String, dynamic>.from(res));
  }

  /// Manager: update draft fields (headline, image_url, target_url). RLS may restrict to own business.
  Future<void> updateDraft(String id, {String? headline, String? imageUrl, String? targetUrl}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (headline != null) data['headline'] = headline;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (targetUrl != null) data['target_url'] = targetUrl;
    if (data.isEmpty) return;
    await client.from('business_ads').update(data).eq('id', id);
  }

  /// Admin: update status (e.g. approve -> active, or reject).
  Future<void> updateStatus(String id, String status) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_ads').update({'status': status}).eq('id', id);
  }

  /// Admin: delete ad.
  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_ads').delete().eq('id', id);
  }

  /// Business IDs that have an active ad for Explore placements (directory_top, category_banner, search_results).
  /// Used to show sponsored listings at top when filtered and blue border on cards.
  Future<Set<String>> getActiveSponsoredBusinessIdsForExplore() async {
    final client = _client;
    if (client == null) return {};
    const explorePlacements = ['directory_top', 'category_banner', 'search_results'];
    try {
      final list = await client
          .from('business_ads')
          .select('business_id, ad_packages(placement)')
          .eq('status', 'active');
      final ids = <String>{};
      for (final e in list as List) {
        final row = Map<String, dynamic>.from(e as Map);
        final bid = row['business_id'] as String?;
        if (bid == null) continue;
        final pkg = row['ad_packages'];
        String? placement;
        if (pkg is Map<String, dynamic>) {
          placement = pkg['placement'] as String?;
        } else if (pkg is List && pkg.isNotEmpty && pkg.first is Map<String, dynamic>) {
          placement = (pkg.first as Map<String, dynamic>)['placement'] as String?;
        }
        if (placement != null && explorePlacements.contains(placement)) {
          ids.add(bid);
        }
      }
      return ids;
    } catch (_) {
      return {};
    }
  }
}
