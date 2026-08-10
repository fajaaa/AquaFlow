class AdminSettlementException implements Exception {
  const AdminSettlementException(this.message);

  final String message;

  @override
  String toString() => message;
}
