import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/user_plans_api.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_plans_repository.g.dart';

/// User subscription plans (pricing-and-ads-cheatsheet §2.3). Public SELECT; admin-only write.
class UserPlansRepository {
  UserPlansRepository({UserPlansApi? api}) : _api = api ?? UserPlansApi(ApiClient.instance);
  final UserPlansApi _api;

  Future<List<UserPlan>> list() async {
    return _api.list();
  }

  Future<UserPlan?> getById(String id) async {
    return _api.getById(id);
  }

  Future<void> insert(UserPlan plan) async {
    await _api.insert(plan);
  }

  Future<void> update(UserPlan plan) async {
    await _api.update(plan);
  }

  Future<void> delete(String id) async {
    await _api.delete(id);
  }
}

@riverpod
UserPlansRepository userPlansRepository(UserPlansRepositoryRef ref) {
  return UserPlansRepository(api: ref.watch(userPlansApiProvider));
}
