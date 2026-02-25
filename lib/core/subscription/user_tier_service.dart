import 'package:flutter/foundation.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/data/repositories/user_subscriptions_repository.dart';
import 'package:my_app/core/subscription/resolved_permissions.dart';

/// Loads current user's subscription + plan, resolves permissions (tier defaults
/// overridden by plan.features), and exposes them to the app.
class UserTierService {
  UserTierService({
    required AuthRepository authRepository,
    required UserSubscriptionsRepository subscriptionsRepository,
    required UserPlansRepository plansRepository,
  })  : _auth = authRepository,
        _subRepo = subscriptionsRepository,
        _planRepo = plansRepository {
    _auth.authStateChanges.listen((_) => _refresh());
  }

  final AuthRepository _auth;
  final UserSubscriptionsRepository _subRepo;
  final UserPlansRepository _planRepo;

  final ValueNotifier<ResolvedPermissions?> permissions =
      ValueNotifier<ResolvedPermissions?>(null);

  /// Current resolved permissions. Null until first load; use [ResolvedPermissions.free]
  /// for logged-out or no-subscription when you need a non-null value.
  ResolvedPermissions? get value => permissions.value;

  /// Call after auth or subscription changes to refresh cached permissions.
  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      permissions.value = ResolvedPermissions.free;
      return;
    }
    final sub = await _subRepo.getByUserId(userId);
    if (sub == null) {
      permissions.value = ResolvedPermissions.free;
      return;
    }
    final plan = await _planRepo.getById(sub.planId);
    if (plan == null) {
      permissions.value = ResolvedPermissions.free;
      return;
    }
    permissions.value = _resolve(plan);
  }

  /// Tier defaults; plan.features override when present.
  ResolvedPermissions _resolve(UserPlan plan) {
    final tier = plan.tier.toLowerCase();
    final f = plan.features;

    int? maxFavorites;
    bool canClaimDeals;
    bool canSeeExclusiveDeals;
    bool canSubmitBusiness;

    if (tier == 'plus' || tier == 'pro') {
      maxFavorites = null;
      canClaimDeals = true;
      canSeeExclusiveDeals = true;
      canSubmitBusiness = true;
    } else {
      maxFavorites = 3;
      canClaimDeals = false;
      canSeeExclusiveDeals = false;
      canSubmitBusiness = false;
    }

    if (f.containsKey('max_favorites')) {
      final v = f['max_favorites'];
      if (v is int) maxFavorites = v;
      if (v is num) maxFavorites = v.toInt();
    }
    if (f.containsKey('exclusive_deals')) {
      final v = f['exclusive_deals'];
      if (v is bool) canSeeExclusiveDeals = v;
    }
    if (f.containsKey('can_claim_deals')) {
      final v = f['can_claim_deals'];
      if (v is bool) canClaimDeals = v;
    }
    if (f.containsKey('can_submit_business')) {
      final v = f['can_submit_business'];
      if (v is bool) canSubmitBusiness = v;
    }

    return ResolvedPermissions(
      tier: plan.tier,
      maxFavorites: maxFavorites,
      canClaimDeals: canClaimDeals,
      canSeeExclusiveDeals: canSeeExclusiveDeals,
      canSubmitBusiness: canSubmitBusiness,
      planName: plan.name,
    );
  }
}
