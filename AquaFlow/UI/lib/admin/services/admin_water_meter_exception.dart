class AdminWaterMeterException implements Exception {
  const AdminWaterMeterException(this.message);

  final String message;

  @override
  String toString() => message;
}
