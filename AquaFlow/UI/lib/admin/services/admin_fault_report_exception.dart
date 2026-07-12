class AdminFaultReportException implements Exception {
  const AdminFaultReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
