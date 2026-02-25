import 'package:my_app/core/stripe/stripe_checkout_exception.dart';
export 'package:my_app/core/stripe/stripe_checkout_exception.dart';
import 'package:my_app/core/stripe/stripe_config.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls Stripe-related Supabase edge functions (stripe-cheatsheet §2–4).
/// Requires user to be signed in (JWT sent with each request).
class StripeCheckoutService {
  StripeCheckoutService();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Creates a Stripe Checkout Session and returns the URL to redirect the user.
  /// [priceId] Stripe Price ID.
  /// [mode] 'subscription' or 'payment'.
  /// [metadata] Must include type (e.g. user_subscription) and reference_id (plan id).
  /// Throws [StripeCheckoutException] on failure.
  Future<String> createCheckoutSession({
    required String priceId,
    String mode = 'subscription',
    String? successUrl,
    String? cancelUrl,
    Map<String, String>? metadata,
  }) async {
    final client = _client;
    if (client == null) throw StripeCheckoutException('Supabase not configured');
    if (client.auth.currentUser == null) {
      throw StripeCheckoutException('Must be signed in to start checkout');
    }
    final body = <String, dynamic>{
      'price_id': priceId,
      'mode': mode,
      if (successUrl != null && successUrl.isNotEmpty) 'success_url': successUrl,
      if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancel_url': cancelUrl,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
    final response = await client.functions.invoke(
      'stripe-checkout',
      body: body,
    );
    if (response.status != 200) {
      final data = response.data;
      String? msg;
      if (data is Map) {
        msg = (data['message'] ?? data['error'] ?? data['error_description'])?.toString();
        if (msg == null && data.isNotEmpty) {
          msg = data.toString();
        }
      }
      if (msg == null || msg.isEmpty) msg = data?.toString();
      throw StripeCheckoutException(msg ?? 'Checkout failed (${response.status})');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) throw StripeCheckoutException('Invalid response');
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) throw StripeCheckoutException('No checkout URL in response');
    return url;
  }

  /// Checks whether the current user has an active Stripe subscription.
  /// Call after login, on profile load, or when returning from checkout.
  Future<StripeSubscriptionStatus> checkSubscription() async {
    final client = _client;
    if (client == null) return const StripeSubscriptionStatus(subscribed: false);
    if (client.auth.currentUser == null) return const StripeSubscriptionStatus(subscribed: false);
    final response = await client.functions.invoke('check-subscription');
    if (response.status != 200) return const StripeSubscriptionStatus(subscribed: false);
    final data = response.data;
    if (data is! Map<String, dynamic>) return const StripeSubscriptionStatus(subscribed: false);
    final subscribed = data['subscribed'] as bool? ?? false;
    if (!subscribed) return const StripeSubscriptionStatus(subscribed: false);
    return StripeSubscriptionStatus(
      subscribed: true,
      productId: data['product_id'] as String?,
      subscriptionEnd: data['subscription_end'] as String?,
      subscriptions: data['subscriptions'] is List
          ? (data['subscriptions'] as List)
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
              .whereType<Map<String, dynamic>>()
              .toList()
          : null,
    );
  }

  /// Creates a Stripe Customer Portal session and returns the URL.
  /// User can manage subscription, payment method, and billing history.
  Future<String> createCustomerPortalSession({String? returnUrl}) async {
    final client = _client;
    if (client == null) throw StripeCheckoutException('Supabase not configured');
    if (client.auth.currentUser == null) {
      throw StripeCheckoutException('Must be signed in to open billing portal');
    }
    final body = <String, dynamic>{
      if (returnUrl != null && returnUrl.isNotEmpty) 'return_url': returnUrl,
    };
    final response = await client.functions.invoke(
      'customer-portal',
      body: body.isNotEmpty ? body : null,
    );
    if (response.status != 200) {
      final msg = response.data is Map ? (response.data as Map)['message']?.toString() : null;
      throw StripeCheckoutException(msg ?? response.data?.toString() ?? 'Portal failed');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) throw StripeCheckoutException('Invalid response');
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) throw StripeCheckoutException('No portal URL in response');
    return url;
  }

  /// Builds success and cancel URLs for user subscription checkout.
  /// Uses [StripeConfig.returnBaseUrl] if set. When null/empty, the app omits
  /// these from the request and the stripe-checkout Edge Function builds them
  /// from STRIPE_RETURN_BASE_URL (Supabase secret).
  static String? successUrl() {
    final base = StripeConfig.returnBaseUrl;
    if (base.isEmpty) return null;
    final suffix = base.endsWith('/') ? '' : '/';
    return '$base${suffix}profile?checkout=success';
  }

  static String? cancelUrl() {
    final base = StripeConfig.returnBaseUrl;
    if (base.isEmpty) return null;
    final suffix = base.endsWith('/') ? '' : '/';
    return '$base${suffix}profile?checkout=canceled';
  }

  /// Portal return URL (e.g. back to profile).
  static String? portalReturnUrl() {
    final base = StripeConfig.returnBaseUrl;
    if (base.isEmpty) return null;
    final suffix = base.endsWith('/') ? '' : '/';
    return '$base${suffix}profile';
  }
}

class StripeSubscriptionStatus {
  const StripeSubscriptionStatus({
    required this.subscribed,
    this.productId,
    this.subscriptionEnd,
    this.subscriptions,
  });
  final bool subscribed;
  final String? productId;
  final String? subscriptionEnd;
  final List<Map<String, dynamic>>? subscriptions;
}
