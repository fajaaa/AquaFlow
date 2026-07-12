class CustomerFaultReportException implements Exception {
  const CustomerFaultReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
