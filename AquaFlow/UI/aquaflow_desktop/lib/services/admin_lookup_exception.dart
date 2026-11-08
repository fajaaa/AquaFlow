class AdminLookupException implements Exception {
  const AdminLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
