/// A checkout session as returned by `POST /Invoices/{id}/checkout`
/// (`CheckoutSessionResponse`). The amount/currency/status always come from
/// the server - there is no client-supplied amount anywhere in this flow.
class CustomerCheckoutSession {
  const CustomerCheckoutSession({
    required this.paymentId,
    required this.invoiceId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.providerTransactionId,
    required this.redirectUrl,
    required this.status,
  });

  final int paymentId;
  final int invoiceId;
  final double amount;
  final String currency;
  final String provider;
  final String providerTransactionId;
  final String? redirectUrl;
  final String status;

  factory CustomerCheckoutSession.fromJson(Map<String, dynamic> json) {
    return CustomerCheckoutSession(
      paymentId: (json['paymentId'] as num?)?.toInt() ?? 0,
      invoiceId: (json['invoiceId'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? '') as String,
      provider: (json['provider'] ?? '') as String,
      providerTransactionId: (json['providerTransactionId'] ?? '') as String,
      redirectUrl: json['redirectUrl'] as String?,
      status: (json['status'] ?? '') as String,
    );
  }
}
