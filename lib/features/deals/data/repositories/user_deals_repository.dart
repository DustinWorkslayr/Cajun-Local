import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/deals/data/api/deals_api.dart';
import 'package:cajun_local/features/deals/data/models/user_deal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_deals_repository.g.dart';

/// User-deals (backend-cheatsheet §1). RLS: own SELECT/INSERT; UPDATE admin only.
/// Tracks which deals the user has claimed. Redemption (used_at) is admin or future redeem_deal().
class UserDealsRepository {
  UserDealsRepository({DealsApi? api}) : _api = api ?? DealsApi(ApiClient.instance);

  final DealsApi _api;

  /// List deals claimed by [userId] (or current user if null). Returns [] when no user.
  Future<List<UserDeal>> listForUser(String? userId) async {
    final list = await _api.listClaimedDeals();
    return list.map((e) => UserDeal.fromJson(e)).toList();
  }

  /// Deal IDs claimed by the current user. Convenience for UI.
  Future<Set<String>> getClaimedDealIds(String? userId) async {
    final list = await listForUser(userId);
    return list.map((e) => e.dealId).toSet();
  }

  /// Claim a deal for [userId] (or current user if null).
  Future<void> claim(String? userId, String dealId) async {
    await _api.claimDeal(dealId);
  }

  /// Whether the current user has claimed this deal.
  Future<bool> hasClaimed(String? userId, String dealId) async {
    final ids = await getClaimedDealIds(userId);
    return ids.contains(dealId);
  }

  /// Admin: list all claimed deals (user_deals).
  Future<List<UserDeal>> listForAdmin() async {
    // Current backend doesn't have a specific admin-list-all-claims but we can add or use listClaimed with filter
    return [];
  }

  /// Admin: set used_at on a user_deal (mark as redeemed).
  Future<void> setUsedAt(String userId, String dealId) async {
    // For now we assume the current user is marking it as used (or admin endpoint is same)
    await _api.markDealAsUsed(dealId);
  }
}

@riverpod
UserDealsRepository userDealsRepository(UserDealsRepositoryRef ref) {
  return UserDealsRepository(api: ref.watch(dealsApiProvider));
}
