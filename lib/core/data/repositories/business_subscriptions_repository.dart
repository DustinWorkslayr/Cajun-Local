import 'package:my_app/core/data/models/business_subscription.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DTO for subscription with joined plan display info.
class BusinessSubscriptionWithPlan {
  const BusinessSubscriptionWithPlan({
    required this.subscription,
    required this.planName,
    required this.planTier,
  });
  final BusinessSubscription subscription;
  final String planName;
  final String planTier;
}

/// Business subscription records (pricing-and-ads-cheatsheet §2.2).
/// One active subscription per business; links to business_plans for tier.
class BusinessSubscriptionsRepository {
  BusinessSubscriptionsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Fetches the business's subscription (any status) with plan name and tier for display.
  Future<BusinessSubscriptionWithPlan?> getByBusinessId(String businessId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client
          .from('business_subscriptions')
          .select('*, business_plans(name, tier)')
          .eq('business_id', businessId)
          .maybeSingle();
      if (res == null) return null;
      final row = Map<String, dynamic>.from(res);
      final plans = row['business_plans'];
      row.remove('business_plans');
      final sub = BusinessSubscription.fromJson(row);
      String planName = '';
      String planTier = '';
      if (plans is Map<String, dynamic>) {
        planName = plans['name'] as String? ?? '';
        planTier = plans['tier'] as String? ?? '';
      } else if (plans is List && plans.isNotEmpty && plans.first is Map<String, dynamic>) {
        final p = plans.first as Map<String, dynamic>;
        planName = p['name'] as String? ?? '';
        planTier = p['tier'] as String? ?? '';
      }
      return BusinessSubscriptionWithPlan(
        subscription: sub,
        planName: planName,
        planTier: planTier,
      );
    } catch (_) {
      return null;
    }
  }

  /// Admin: assign or change plan without Stripe checkout. Upserts one row per business.
  /// If [trialDays] is set, status is 'trialing' and period end is now + trialDays; otherwise 'active' with 30-day period.
  Future<void> assignPlanWithoutCheckout(
    String businessId,
    String planId, {
    int? trialDays,
  }) async {
    final client = _client;
    if (client == null) return;
    final now = DateTime.now().toUtc();
    final periodEnd = trialDays != null
        ? now.add(Duration(days: trialDays))
        : now.add(const Duration(days: 30));
    final status = trialDays != null ? 'trialing' : 'active';
    final existing = await client
        .from('business_subscriptions')
        .select('id')
        .eq('business_id', businessId)
        .maybeSingle();
    if (existing != null) {
      await client.from('business_subscriptions').update({
        'plan_id': planId,
        'status': status,
        'billing_interval': 'monthly',
        'current_period_start': now.toIso8601String(),
        'current_period_end': periodEnd.toIso8601String(),
        'stripe_subscription_id': null,
        'stripe_customer_id': null,
        'canceled_at': null,
      }).eq('business_id', businessId);
    } else {
      await client.from('business_subscriptions').insert({
        'business_id': businessId,
        'plan_id': planId,
        'status': status,
        'billing_interval': 'monthly',
        'current_period_start': now.toIso8601String(),
        'current_period_end': periodEnd.toIso8601String(),
      });
    }
  }

  /// Admin: remove subscription for a business (downgrade to no plan).
  Future<void> removeSubscription(String businessId) async {
    final client = _client;
    if (client == null) return;
    await client.from('business_subscriptions').delete().eq('business_id', businessId);
  }

  /// Returns the plan tier for the business's active subscription (e.g. 'free', 'basic', 'premium', 'enterprise').
  /// Null if no active subscription or not configured.
  Future<String?> getActivePlanTierForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final res = await client
          .from('business_subscriptions')
          .select('plan_id, business_plans(tier)')
          .eq('business_id', businessId)
          .eq('status', 'active')
          .maybeSingle();
      if (res == null) return null;
      final plans = res['business_plans'];
      if (plans is Map<String, dynamic>) {
        final tier = plans['tier'];
        return tier is String ? tier : null;
      }
      if (plans is List && plans.isNotEmpty && plans.first is Map<String, dynamic>) {
        final tier = (plans.first as Map<String, dynamic>)['tier'];
        return tier is String ? tier : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the business has the highest tier (enterprise) — show "Partner" badge.
  Future<bool> isPartnerBusiness(String businessId) async {
    final tier = await getActivePlanTierForBusiness(businessId);
    return tier?.toLowerCase() == 'enterprise';
  }

  /// Returns map of business_id -> tier for all given businesses with an active subscription.
  Future<Map<String, String>> getActivePlanTiersForBusinesses(List<String> businessIds) async {
    final client = _client;
    if (client == null || businessIds.isEmpty) return {};
    final unique = businessIds.toSet().toList();
    try {
      final list = await client
          .from('business_subscriptions')
          .select('business_id, business_plans(tier)')
          .inFilter('business_id', unique)
          .eq('status', 'active');
      final map = <String, String>{};
      for (final e in list as List) {
        final row = Map<String, dynamic>.from(e as Map);
        final bid = row['business_id'] as String?;
        if (bid == null) continue;
        final plans = row['business_plans'];
        String? tier;
        if (plans is Map<String, dynamic>) {
          tier = plans['tier'] as String?;
        } else if (plans is List && plans.isNotEmpty && plans.first is Map<String, dynamic>) {
          tier = (plans.first as Map<String, dynamic>)['tier'] as String?;
        }
        if (tier != null) map[bid] = tier;
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
