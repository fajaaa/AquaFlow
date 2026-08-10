class CustomerInvoiceException implements Exception {
  const CustomerInvoiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
