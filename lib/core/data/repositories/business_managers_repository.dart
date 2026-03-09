import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/business_managers_api.dart';
import 'package:my_app/core/data/models/business_manager_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_managers_repository.g.dart';

/// Business managers (backend-cheatsheet §2). Admin or existing manager can insert.
class BusinessManagersRepository {
  BusinessManagersRepository({BusinessManagersApi? api}) : _api = api ?? BusinessManagersApi(ApiClient.instance);

  final BusinessManagersApi _api;

  /// List users with access to this business (callable by admin or manager).
  Future<List<BusinessManagerEntry>> listManagersForBusiness(String businessId) async {
    final list = await _api.listManagers(businessId);
    return list.map((e) => BusinessManagerEntry.fromJson(e)).toList();
  }

  /// Resolve user id by email for adding team access (callable by admin or manager).
  Future<String?> lookupUserByEmail(String businessId, String email) async {
    try {
      final res = await _api.lookupUser(businessId, email);
      return res['user_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// One user_id to notify for a business (first manager). Admin use for approval emails.
  Future<String?> getFirstManagerUserId(String businessId) async {
    final list = await _api.listManagers(businessId);
    if (list.isEmpty) return null;
    return list.first['user_id'] as String?;
  }

  /// List business IDs that the user manages.
  Future<List<String>> listBusinessIdsForUser(String userId) async {
    final list = await _api.listManagedBusinesses();
    return list.map((e) => e['id'] as String).toList();
  }

  /// Add a user as manager (admin or existing manager).
  Future<void> insert(String businessId, String userId, {String role = 'owner'}) async {
    await _api.addManager(businessId, userId, role: role);
  }

  /// Remove a manager from a business (admin or existing manager).
  Future<void> delete(String businessId, String userId) async {
    await _api.removeManager(businessId, userId);
  }
}

@riverpod
BusinessManagersRepository businessManagersRepository(BusinessManagersRepositoryRef ref) {
  return BusinessManagersRepository(api: ref.watch(businessManagersApiProvider));
}
