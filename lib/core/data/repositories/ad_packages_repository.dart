import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/business_ads_api.dart';
import 'package:my_app/core/data/models/ad_package.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ad_packages_repository.g.dart';

/// Ad packages (pricing-and-ads-cheatsheet §2.5). Public SELECT; admin-only write.
class AdPackagesRepository {
  AdPackagesRepository({BusinessAdsApi? api}) : _api = api ?? BusinessAdsApi(ApiClient.instance);

  final BusinessAdsApi _api;

  Future<List<AdPackage>> list({bool activeOnly = false}) async {
    final list = await _api.listPackages(activeOnly: activeOnly);
    return list.map((e) => AdPackage.fromJson(e)).toList();
  }

  Future<AdPackage?> getById(String id) async {
    try {
      final res = await _api.getPackageById(id);
      return AdPackage.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> insert(AdPackage pkg) async {
    await _api.createPackage(pkg.toJson());
  }

  Future<void> update(AdPackage pkg) async {
    await _api.updatePackage(pkg.id, pkg.toJson());
  }

  Future<void> delete(String id) async {
    await _api.deletePackage(id);
  }
}

@riverpod
AdPackagesRepository adPackagesRepository(AdPackagesRepositoryRef ref) {
  return AdPackagesRepository(api: ref.watch(businessAdsApiProvider));
}
