class AdminCollectorException implements Exception {
  const AdminCollectorException(this.message);

  final String message;

  @override
  String toString() => message;
}
