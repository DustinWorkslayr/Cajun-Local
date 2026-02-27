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

  /// Entitlement identifier for Cajun+ (user-level). Must match RevenueCat Dashboard → Entitlements.
  /// Standardized: cajun_plus.
  static const String cajunPlusEntitlementId = 'cajun_plus';

  /// Offering identifier for Cajun+ paywall. Use "user_plans" to show $rc_monthly → cajun_plus_monthly.
  static const String offeringId = 'user_plans';
}
