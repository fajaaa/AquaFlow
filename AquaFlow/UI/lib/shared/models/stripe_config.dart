/// Publishable Stripe config as returned by the anonymous
/// `GET /Payments/stripe-config` (`StripeConfigResponse`).
class StripeConfig {
  const StripeConfig({required this.publishableKey, required this.currency});

  final String publishableKey;
  final String currency;

  factory StripeConfig.fromJson(Map<String, dynamic> json) {
    return StripeConfig(
      publishableKey: (json['publishableKey'] ?? '') as String,
      currency: (json['currency'] ?? '') as String,
    );
  }
}
