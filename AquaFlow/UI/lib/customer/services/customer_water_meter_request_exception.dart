class CustomerWaterMeterRequestException implements Exception {
  const CustomerWaterMeterRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
