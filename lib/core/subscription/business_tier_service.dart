import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';

/// Cajun Local business subscription tiers controlling deal creation and features.
/// Resolved from business_plans.tier: free → Free, basic → Local+, premium/enterprise → Local Partner.
enum BusinessTier {
  free,
  localPlus,
  localPartner,
}

/// Deal type values stored in DB. Simple = basic promotions; advanced = Flash, Member-only.
class DealTypes {
  DealTypes._();

  static const String percentage = 'percentage';
  static const String fixed = 'fixed';
  static const String bogo = 'bogo';
  static const String freebie = 'freebie';
  static const String other = 'other';

  /// Advanced types: only Local Partner can create these.
  static const String flash = 'flash';
  static const String memberOnly = 'member_only';

  static const List<String> simple = [percentage, fixed, bogo, freebie, other];
  static const List<String> advanced = [flash, memberOnly];

  static bool isSimple(String dealType) => simple.contains(dealType);
  static bool isAdvanced(String dealType) => advanced.contains(dealType);
}

/// Resolves business plan tier and answers deal/permission questions for Cajun Local.
class BusinessTierService {
  BusinessTierService({
    BusinessSubscriptionsRepository? subscriptionsRepository,
  }) : _subRepo = subscriptionsRepository ?? BusinessSubscriptionsRepository();

  final BusinessSubscriptionsRepository _subRepo;

  /// Resolves plan tier (free, basic, premium, enterprise, or local_plus/local_partner) to Cajun Local tier.
  /// No subscription or plan tier 'free' → [BusinessTier.free].
  /// 'basic' or 'local_plus' → [BusinessTier.localPlus]. 'premium', 'enterprise', or 'local_partner' → [BusinessTier.localPartner].
  static BusinessTier fromPlanTier(String? planTier) {
    if (planTier == null || planTier.isEmpty) return BusinessTier.free;
    final t = planTier.toLowerCase();
    if (t == 'basic' || t == 'local_plus') return BusinessTier.localPlus;
    if (t == 'premium' || t == 'enterprise' || t == 'local_partner') return BusinessTier.localPartner;
    return BusinessTier.free;
  }

  /// Current tier for [businessId]. Uses active business_subscriptions + business_plans.
  Future<BusinessTier> getTierForBusiness(String businessId) async {
    final planTier = await _subRepo.getActivePlanTierForBusiness(businessId);
    return fromPlanTier(planTier);
  }

  /// Max number of active deals allowed for this tier.
  /// Free: 1, Local+: 3, Local Partner: unlimited (use a high cap for UI).
  static int maxActiveDeals(BusinessTier tier) {
    switch (tier) {
      case BusinessTier.free:
        return 1;
      case BusinessTier.localPlus:
        return 3;
      case BusinessTier.localPartner:
        return 999;
    }
  }

  /// Max number of amenities a business can select. Free: 4, Local+ or Local Partner: 8.
  static int maxAmenities(BusinessTier tier) {
    switch (tier) {
      case BusinessTier.free:
        return 4;
      case BusinessTier.localPlus:
      case BusinessTier.localPartner:
        return 8;
    }
  }

  /// Whether this tier can create a deal of type [dealType].
  static bool canCreateDealType(BusinessTier tier, String dealType) {
    if (DealTypes.isSimple(dealType)) {
      return true; // Free and Local+ can only create simple; limit enforced by max active deals.
    }
    if (DealTypes.isAdvanced(dealType)) return tier == BusinessTier.localPartner;
    return true; // unknown type treat as allowed for partner only to be safe
  }

  /// Whether this tier can create punch card (loyalty) programs.
  static bool canCreatePunchCard(BusinessTier tier) {
    return tier == BusinessTier.localPartner;
  }

  /// Whether this tier can schedule deal start/end dates (basic scheduling).
  static bool canScheduleDealDates(BusinessTier tier) {
    return tier == BusinessTier.localPlus || tier == BusinessTier.localPartner;
  }

  /// Display name for tier.
  static String tierDisplayName(BusinessTier tier) {
    switch (tier) {
      case BusinessTier.free:
        return 'Free';
      case BusinessTier.localPlus:
        return 'Local+';
      case BusinessTier.localPartner:
        return 'Local Partner';
    }
  }

  /// Short upgrade message when blocked on deal limit.
  static String upgradeMessageForDealLimit(BusinessTier current) {
    switch (current) {
      case BusinessTier.free:
        return 'Upgrade to Local+ to run up to 3 deals, or Local Partner for unlimited deals and Flash, Loyalty, and Member-only deals.';
      case BusinessTier.localPlus:
        return 'Upgrade to Local Partner for unlimited deals and Flash, Loyalty, and Member-only deals.';
      case BusinessTier.localPartner:
        return '';
    }
  }

  /// Short upgrade message when blocked on advanced deal type or punch cards.
  static String upgradeMessageForAdvancedFeatures() {
    return 'Upgrade to Local Partner to create Flash Deals, Loyalty punch cards, and Member-only deals.';
  }

  /// Short upgrade message when blocked on amenity limit (free at 4).
  static String upgradeMessageForAmenityLimit() {
    return 'Upgrade to Local+ or Local Partner to add up to 8 amenities.';
  }
}
