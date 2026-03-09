import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/business_ads_api.dart';
import 'package:my_app/core/data/models/business_ad.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_ads_repository.g.dart';

/// Business ads (pricing-and-ads-cheatsheet §2.6). Managers INSERT (draft); admin UPDATE/DELETE.
class BusinessAdsRepository {
  BusinessAdsRepository({BusinessAdsApi? api}) : _api = api ?? BusinessAdsApi(ApiClient.instance);

  final BusinessAdsApi _api;

  /// List ads for a business.
  Future<List<BusinessAd>> listByBusiness(String businessId) async {
    final list = await _api.listAds(businessId: businessId);
    return list.map((e) => BusinessAd.fromJson(e)).toList();
  }

  /// Admin: list all ads, optional status filter.
  Future<List<BusinessAd>> listAll({String? status}) async {
    final list = await _api.listAds(status: status);
    return list.map((e) => BusinessAd.fromJson(e)).toList();
  }

  Future<BusinessAd?> getById(String id) async {
    try {
      final res = await _api.getAdById(id);
      return BusinessAd.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Manager: insert draft ad.
  Future<BusinessAd?> insertDraft({
    required String businessId,
    required String packageId,
    String? headline,
    String? imageUrl,
    String? targetUrl,
  }) async {
    final res = await _api.createAd({
      'business_id': businessId,
      'package_id': packageId,
      'headline': headline,
      'image_url': imageUrl,
      'target_url': targetUrl,
    });
    return BusinessAd.fromJson(res);
  }

  /// Manager: update draft fields (headline, image_url, target_url).
  Future<void> updateDraft(String id, {String? headline, String? imageUrl, String? targetUrl}) async {
    final data = <String, dynamic>{};
    if (headline != null) data['headline'] = headline;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (targetUrl != null) data['target_url'] = targetUrl;
    if (data.isEmpty) return;
    await _api.updateAd(id, data);
  }

  /// Admin: update status.
  Future<void> updateStatus(String id, String status) async {
    await _api.updateAdStatus(id, status);
  }

  /// Admin: delete ad.
  Future<void> delete(String id) async {
    await _api.deleteAd(id);
  }

  /// Business IDs that have an active ad for Explore placements.
  Future<Set<String>> getActiveSponsoredBusinessIdsForExplore() async {
    const explorePlacements = ['directory_top', 'category_banner', 'search_results'];
    try {
      final list = await _api.listActiveAds();
      final ids = <String>{};
      for (final e in list) {
        final bid = e['business_id'] as String?;
        final placement = e['placement'] as String?; // Backend should include this in Out schema or relate it
        if (bid != null && placement != null && explorePlacements.contains(placement)) {
          ids.add(bid);
        }
      }
      return ids;
    } catch (_) {
      return {};
    }
  }
}

@riverpod
BusinessAdsRepository businessAdsRepository(BusinessAdsRepositoryRef ref) {
  return BusinessAdsRepository(api: ref.watch(businessAdsApiProvider));
}
