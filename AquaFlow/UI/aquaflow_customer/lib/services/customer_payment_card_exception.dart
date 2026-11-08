class CustomerPaymentCardException implements Exception {
  const CustomerPaymentCardException(this.message, {this.isNetworkError = false});

  final String message;
  final bool isNetworkError;

  @override
  String toString() => message;
}
