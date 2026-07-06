class CustomerWaterMeterException implements Exception {
  const CustomerWaterMeterException(this.message);

  final String message;

  @override
  String toString() => message;
}
