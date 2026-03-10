import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/stripe/stripe_checkout_exception.dart';
import 'package:cajun_local/core/stripe/stripe_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:cajun_local/core/stripe/stripe_checkout_exception.dart';

part 'stripe_checkout_service.g.dart';

/// Calls Stripe-related FastAPI endpoints (stripe-cheatsheet §2–4).
class StripeCheckoutService {
  StripeCheckoutService({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  /// Creates a Stripe Checkout Session and returns the URL to redirect the user.
  Future<String> createCheckoutSession({
    required String priceId,
    String mode = 'subscription',
    String? successUrl,
    String? cancelUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.dio.post(
        '/payments/checkout',
        data: {
          'price_id': priceId,
          'mode': mode,
          if (successUrl != null) 'success_url': successUrl,
          if (cancelUrl != null) 'cancel_url': cancelUrl,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw StripeCheckoutException(e.response?.data?['detail'] ?? 'Checkout failed');
    }
  }

  /// Checks whether the current user has an active Stripe subscription.
  Future<StripeSubscriptionStatus> checkSubscription() async {
    try {
      final response = await _client.dio.get('/payments/check-subscription');
      final data = response.data as Map<String, dynamic>;
      final subscribed = data['subscribed'] as bool? ?? false;
      if (!subscribed) return const StripeSubscriptionStatus(subscribed: false);

      return StripeSubscriptionStatus(
        subscribed: true,
        productId: data['product_id'] as String?,
        subscriptionEnd: data['subscription_end']?.toString(),
        subscriptions: data['subscriptions'] is List
            ? (data['subscriptions'] as List)
                  .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
                  .whereType<Map<String, dynamic>>()
                  .toList()
            : null,
      );
    } catch (e) {
      return const StripeSubscriptionStatus(subscribed: false);
    }
  }

  /// Creates a Stripe Customer Portal session and returns the URL.
  Future<String> createCustomerPortalSession({String? returnUrl}) async {
    try {
      final response = await _client.dio.post(
        '/payments/customer-portal',
        data: {if (returnUrl != null) 'return_url': returnUrl},
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw StripeCheckoutException(e.response?.data?['detail'] ?? 'Portal failed');
    }
  }

  /// Builds success and cancel URLs for user subscription checkout.
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
  const StripeSubscriptionStatus({required this.subscribed, this.productId, this.subscriptionEnd, this.subscriptions});
  final bool subscribed;
  final String? productId;
  final String? subscriptionEnd;
  final List<Map<String, dynamic>>? subscriptions;
}

@riverpod
StripeCheckoutService stripeCheckoutService(StripeCheckoutServiceRef ref) {
  return StripeCheckoutService(client: ApiClient.instance);
}
