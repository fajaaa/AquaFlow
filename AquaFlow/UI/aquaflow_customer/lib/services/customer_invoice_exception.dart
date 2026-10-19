class CustomerInvoiceException implements Exception {
  const CustomerInvoiceException(this.message, {this.isNetworkError = false});

  final String message;

  /// True when the request may never have reached the server, or its
  /// response was lost (no connection, timeout, transport error) - i.e. the
  /// outcome is unknown. The checkout flow resends the same idempotency key
  /// in that case instead of starting a new payment attempt.
  final bool isNetworkError;

  @override
  String toString() => message;
}
