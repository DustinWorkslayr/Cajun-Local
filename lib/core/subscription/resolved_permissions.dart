/// Resolved permissions for the current user: tier defaults overridden by plan.features.
library;

/// Tier defaults: free = limited; plus/pro = full. Plan.features can override per key.
class ResolvedPermissions {
  const ResolvedPermissions({
    required this.tier,
    required this.maxFavorites,
    required this.canClaimDeals,
    required this.canSeeExclusiveDeals,
    required this.canSubmitBusiness,
    this.planName,
  });

  /// Tier from user_plans: free, plus, or pro. No subscription => free.
  final String tier;

  /// Max favorites allowed; null means unlimited.
  final int? maxFavorites;

  final bool canClaimDeals;
  final bool canSeeExclusiveDeals;
  final bool canSubmitBusiness;

  /// Display name of the plan, if available.
  final String? planName;

  /// True if the user can use Ask Local. Included in Cajun+ Membership ($2.99, plus tier) and Pro.
  bool get canUseAskLocal => tier == 'plus' || tier == 'pro';

  /// Free-tier defaults (no subscription or tier == 'free').
  static const ResolvedPermissions free = ResolvedPermissions(
    tier: 'free',
    maxFavorites: 3,
    canClaimDeals: false,
    canSeeExclusiveDeals: false,
    canSubmitBusiness: false,
    planName: null,
  );

  /// Returns true if adding one more favorite would exceed the limit.
  bool wouldExceedFavoritesLimit(int currentCount) {
    if (maxFavorites == null) return false;
    return currentCount >= maxFavorites!;
  }
}
