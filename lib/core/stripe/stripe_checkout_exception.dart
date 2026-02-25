/// Exception thrown when Stripe checkout or portal calls fail.
class StripeCheckoutException implements Exception {
  StripeCheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}
