class AdminConsumptionAlertException implements Exception {
  const AdminConsumptionAlertException(this.message);

  final String message;

  @override
  String toString() => message;
}
