import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/business_claims_api.dart';
import 'package:my_app/core/data/models/business_claim.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_claims_repository.g.dart';

/// Business ownership claims (backend-cheatsheet §2). Admin can list and update status.
class BusinessClaimsRepository {
  BusinessClaimsRepository({BusinessClaimsApi? api}) : _api = api ?? BusinessClaimsApi(ApiClient.instance);

  final BusinessClaimsApi _api;

  static const _limit = 500;

  Future<List<BusinessClaim>> listForAdmin({String? status}) async {
    final list = await _api.listClaims(limit: _limit);
    // Filtering on client side if status is provided, or update backend to support it
    var claims = list.map((e) => BusinessClaim.fromJson(e)).toList();
    if (status != null) {
      claims = claims.where((c) => c.status == status).toList();
    }
    return claims;
  }

  Future<BusinessClaim?> getById(String id) async {
    try {
      final res = await _api.getClaimById(id);
      return BusinessClaim.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    if (status == 'approved') {
      await _api.approveClaim(id);
    } else if (status == 'rejected') {
      await _api.rejectClaim(id);
    }
  }

  /// User submits a claim. Returns new claim id or null on failure.
  Future<String?> insert({required String userId, required String businessId, required String claimDetails}) async {
    final res = await _api.createClaim({'business_id': businessId, 'claim_details': claimDetails});
    return res['id'] as String?;
  }

  /// Get the current user's claim for this business (pending or approved).
  Future<BusinessClaim?> getForUserAndBusiness(String userId, String businessId) async {
    // We can fetch from a new endpoint or filter. Let's filter for now.
    // Actually better to have a dedicated endpoint in future.
    final list = await _api.listClaims(limit: _limit);
    final items = list
        .map((e) => BusinessClaim.fromJson(e))
        .where(
          (c) => c.userId == userId && c.businessId == businessId && (c.status == 'pending' || c.status == 'approved'),
        )
        .toList();
    if (items.isEmpty) return null;
    return items.first;
  }
}

@riverpod
BusinessClaimsRepository businessClaimsRepository(BusinessClaimsRepositoryRef ref) {
  return BusinessClaimsRepository(api: ref.watch(businessClaimsApiProvider));
}
