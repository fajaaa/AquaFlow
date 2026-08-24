class AdminMeterReadingException implements Exception {
  const AdminMeterReadingException(this.message);

  final String message;

  @override
  String toString() => message;
}
