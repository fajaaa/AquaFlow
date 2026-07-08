class CollectorMeterReadingException implements Exception {
  const CollectorMeterReadingException(this.message);

  final String message;

  @override
  String toString() => message;
}
