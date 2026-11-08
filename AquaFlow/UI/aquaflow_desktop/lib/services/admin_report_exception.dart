class AdminReportException implements Exception {
  const AdminReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
