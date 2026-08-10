class AdminWaterMeterRequestException implements Exception {
  const AdminWaterMeterRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
