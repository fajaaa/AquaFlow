class CollectorFaultReportException implements Exception {
  const CollectorFaultReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
