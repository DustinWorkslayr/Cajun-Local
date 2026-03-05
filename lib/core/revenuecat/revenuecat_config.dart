/// RevenueCat API keys and entitlement identifiers for Cajun Local.
/// Get your keys from: https://app.revenuecat.com/ → Project → API keys
library;

/// RevenueCat configuration. Use the same key for both platforms if you have
/// a single project key, or set platform-specific keys from the dashboard.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Default API key (used for both platforms when platform keys are not set).
  /// Replace with your production key for release builds.
  static const String apiKey = 'test_nJvKdUaYxGOweWjVoxBWJNgZKJa';

  /// Optional: iOS-specific API key (starts with appl_). If null, [apiKey] is used.
  static const String? iosApiKey = null;

  /// Optional: Android-specific API key (starts with goog_). If null, [apiKey] is used.
  static const String? androidApiKey = null;

  /// Entitlement identifier for Cajun+ (user-level). Must match RevenueCat Dashboard.
  /// System has only three subscription entitlements: cajun_plus, local_plus, local_partner.
  static const String cajunPlusEntitlementId = 'cajun_plus';

  /// Entitlement IDs for Local+ and Local Partner (business subscriptions).
  static const String localPlusEntitlementId = 'local_plus';
  static const String localPartnerEntitlementId = 'local_partner';

  /// Offering identifier for subscription paywall (Cajun+, Local+, or Local Partner packages).
  static const String offeringId = 'user_plans';

  /// Offering identifier for ad/consumable products (optional). When set, ad purchase looks here first.
  static const String adsOfferingId = 'ad_packages';

  /// Subscription product IDs (Cajun+, Local+, Local Partner only). Configure in stores and Dashboard.
  static const List<String> subscriptionProductIds = [
    'cajun_plus_monthly',
    'cajun_plus_yearly',
    'local_plus_monthly',
    'business_local_plus_yearly',
    'local_partner_monthly',
    'business_local_partner_yearly',
  ];

  /// Advertisement / feature payment product IDs (boosts, placements). Configure in stores and Dashboard.
  static const List<String> advertisementProductIds = [
    'boost_7_day',
    'homepage_feature_7_day',
    'category_feature_7_day',
    'feature_monthly',
  ];
}
