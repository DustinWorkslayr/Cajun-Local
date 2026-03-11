import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/businesses/data/api/business_subscriptions_api.dart';
import 'package:cajun_local/features/businesses/data/models/business_subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_subscriptions_repository.g.dart';

/// DTO for subscription with joined plan display info.
class BusinessSubscriptionWithPlan {
  const BusinessSubscriptionWithPlan({required this.subscription, required this.planName, required this.planTier});
  final BusinessSubscription subscription;
  final String planName;
  final String planTier;
}

/// Business subscription records (pricing-and-ads-cheatsheet §2.2).
/// One active subscription per business; links to business_plans for tier.
class BusinessSubscriptionsRepository {
  BusinessSubscriptionsRepository({BusinessSubscriptionsApi? api})
    : _api = api ?? BusinessSubscriptionsApi(ApiClient.instance);
  final BusinessSubscriptionsApi _api;

  /// Fetches the business's subscription (any status) with plan name and tier for display.
  Future<BusinessSubscriptionWithPlan?> getByBusinessId(String businessId) async {
    try {
      final res = await _api.getByBusinessId(businessId);
      final sub = BusinessSubscription.fromJson(res);
      final plan = res['plan'] as Map<String, dynamic>?;
      return BusinessSubscriptionWithPlan(
        subscription: sub,
        planName: plan?['name'] as String? ?? '',
        planTier: plan?['tier'] as String? ?? '',
      );
    } catch (e) {
      if (e.toString().contains('not_found')) return null;
      return null;
    }
  }

  /// Admin: assign or change plan without Stripe checkout. Upserts one row per business.
  Future<void> assignPlanWithoutCheckout(String businessId, String planId, {int? trialDays}) async {
    final now = DateTime.now().toUtc();
    final periodEnd = trialDays != null ? now.add(Duration(days: trialDays)) : now.add(const Duration(days: 30));
    final status = trialDays != null ? 'trialing' : 'active';

    await _api.assignPlan({
      'business_id': businessId,
      'plan_id': planId,
      'status': status,
      'billing_interval': 'monthly',
      'current_period_start': now.toIso8601String(),
      'current_period_end': periodEnd.toIso8601String(),
    });
  }

  /// Admin: remove subscription for a business (downgrade to no plan).
  Future<void> removeSubscription(String businessId) async {
    await _api.removeSubscription(businessId);
  }

  /// Returns the plan tier for the business's active subscription.
  Future<String?> getActivePlanTierForBusiness(String businessId) async {
    final sub = await getByBusinessId(businessId);
    if (sub == null || sub.subscription.status != 'active') return null;
    return sub.planTier;
  }

  /// Returns true if the business has the highest tier (enterprise) — show "Partner" badge.
  Future<bool> isPartnerBusiness(String businessId) async {
    final tier = await getActivePlanTierForBusiness(businessId);
    return tier?.toLowerCase() == 'enterprise';
  }

  /// Returns map of business_id -> tier for all given businesses with an active subscription.
  Future<Map<String, String>> getActivePlanTiersForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    try {
      return await _api.getActiveTiers(businessIds);
    } catch (_) {
      return {};
    }
  }
}

@riverpod
BusinessSubscriptionsRepository businessSubscriptionsRepository(BusinessSubscriptionsRepositoryRef ref) {
  return BusinessSubscriptionsRepository(api: ref.watch(businessSubscriptionsApiProvider));
}
