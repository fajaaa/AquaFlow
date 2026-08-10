class AdminPaymentException implements Exception {
  const AdminPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
