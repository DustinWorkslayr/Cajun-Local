import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/business_api.dart';
import 'package:my_app/core/data/models/business_hours.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_hours_repository.g.dart';

/// Public read: business_hours (§7).
class BusinessHoursRepository {
  BusinessHoursRepository({BusinessApi? api}) : _api = api ?? BusinessApi(ApiClient.instance);

  final BusinessApi _api;

  Future<List<BusinessHours>> getForBusiness(String businessId) async {
    final list = await _api.getHours(businessId);
    return list.map((e) => BusinessHours.fromJson(e)).toList();
  }

  /// Manager/admin: replace all hours for a business. Pass 7 items (one per day).
  Future<void> setForBusiness(String businessId, List<BusinessHours> hours) async {
    await _api.updateHours(businessId, hours.map((h) => h.toJson()).toList());
  }
}

@riverpod
BusinessHoursRepository businessHoursRepository(BusinessHoursRepositoryRef ref) {
  return BusinessHoursRepository(api: ref.watch(businessApiProvider));
}
