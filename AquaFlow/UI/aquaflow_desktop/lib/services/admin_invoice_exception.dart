class AdminInvoiceException implements Exception {
  const AdminInvoiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
