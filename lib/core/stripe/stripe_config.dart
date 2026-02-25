/// Stripe Price ID mapping for subscriptions (stripe-cheatsheet §6).
/// Replace placeholder IDs with real Stripe Price IDs from the Stripe Dashboard.
/// Business plans: map tier (basic, premium, enterprise) to monthly/yearly price IDs.
/// User plans: map tier (plus, pro) to monthly/yearly price IDs.
library;

/// User subscription tiers and their Stripe Price IDs.
/// reference_id in checkout metadata = user_plans.id from DB.
class StripeConfig {
  StripeConfig._();

  /// Base URL for Stripe redirects (success/cancel). Use your app's web URL or
  /// deep-link scheme (e.g. myapp://) so users return to the app after checkout.
  static String get returnBaseUrl =>
      const String.fromEnvironment('STRIPE_RETURN_BASE_URL', defaultValue: '');

  /// User plans: tier -> { monthly price_id, yearly price_id }.
  /// Replace with real Stripe Price IDs once products exist in Dashboard.
  static const Map<String, StripePriceIds> userPlans = {
    'plus': StripePriceIds(
      monthly: 'price_plus_monthly_placeholder',
      yearly: 'price_plus_yearly_placeholder',
    ),
    'pro': StripePriceIds(
      monthly: 'price_pro_monthly_placeholder',
      yearly: 'price_pro_yearly_placeholder',
    ),
  };

  /// Business plans: tier -> { monthly, yearly } (for future business checkout).
  static const Map<String, StripePriceIds> businessPlans = {
    'basic': StripePriceIds(monthly: 'price_basic_monthly_placeholder', yearly: 'price_basic_yearly_placeholder'),
    'premium': StripePriceIds(monthly: 'price_premium_monthly_placeholder', yearly: 'price_premium_yearly_placeholder'),
    'enterprise': StripePriceIds(monthly: 'price_enterprise_monthly_placeholder', yearly: 'price_enterprise_yearly_placeholder'),
  };

  /// Default user plan tier for "Subscribe" (Cajun+ Membership).
  static const String defaultUserTier = 'plus';

  /// Default billing interval for user subscription checkout.
  static const String defaultUserInterval = 'monthly';
}

class StripePriceIds {
  const StripePriceIds({required this.monthly, required this.yearly});
  final String monthly;
  final String yearly;
}
