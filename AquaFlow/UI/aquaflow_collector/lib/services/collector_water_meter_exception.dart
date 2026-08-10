class CollectorWaterMeterException implements Exception {
  const CollectorWaterMeterException(this.message);

  final String message;

  @override
  String toString() => message;
}
