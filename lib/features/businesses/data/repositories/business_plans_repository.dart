import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/business_plans_api.dart';
import 'package:cajun_local/features/businesses/data/models/business_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_plans_repository.g.dart';

/// Business subscription plans (pricing-and-ads-cheatsheet §2.1). Public SELECT; admin-only write.
class BusinessPlansRepository {
  BusinessPlansRepository({BusinessPlansApi? api}) : _api = api ?? BusinessPlansApi(ApiClient.instance);
  final BusinessPlansApi _api;

  Future<List<BusinessPlan>> list() async {
    return _api.list();
  }

  Future<BusinessPlan?> getById(String id) async {
    return _api.getById(id);
  }

  Future<void> insert(BusinessPlan plan) async {
    final data = plan.toJson()..remove('id');
    await _api.insert(data);
  }

  Future<void> update(BusinessPlan plan) async {
    await _api.update(plan.id, plan.toJson());
  }

  Future<void> delete(String id) async {
    await _api.delete(id);
  }
}

@riverpod
BusinessPlansRepository businessPlansRepository(BusinessPlansRepositoryRef ref) {
  return BusinessPlansRepository(api: ref.watch(businessPlansApiProvider));
}
