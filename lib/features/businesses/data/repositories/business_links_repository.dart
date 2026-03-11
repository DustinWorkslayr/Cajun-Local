import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/business_links_api.dart';
import 'package:cajun_local/features/businesses/data/models/business_link.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_links_repository.g.dart';

/// Public read: business_links (§7).
class BusinessLinksRepository {
  BusinessLinksRepository({BusinessLinksApi? api}) : _api = api ?? BusinessLinksApi(ApiClient.instance);

  final BusinessLinksApi _api;

  Future<List<BusinessLink>> getForBusiness(String businessId) async {
    final list = await _api.listLinks(businessId: businessId);
    return list.map((e) => BusinessLink.fromJson(e)).toList();
  }

  /// Manager/admin: insert a link.
  Future<String> insert({required String businessId, required String url, String? label, int? sortOrder}) async {
    final res = await _api.createLink({
      'business_id': businessId,
      'url': url,
      'label': label,
      'sort_order': sortOrder ?? 0,
    });
    return res['id'] as String;
  }

  /// Manager/admin: update label, url, sort_order.
  Future<void> update(String id, {String? url, String? label, int? sortOrder}) async {
    final data = <String, dynamic>{};
    if (url != null) data['url'] = url;
    if (label != null) data['label'] = label;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await _api.updateLink(id, data);
  }

  /// Manager/admin: delete a link.
  Future<void> delete(String id) async {
    await _api.deleteLink(id);
  }
}

@riverpod
BusinessLinksRepository businessLinksRepository(BusinessLinksRepositoryRef ref) {
  return BusinessLinksRepository(api: ref.watch(businessLinksApiProvider));
}
