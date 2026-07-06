class CollectorWaterMeterRequestException implements Exception {
  const CollectorWaterMeterRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
