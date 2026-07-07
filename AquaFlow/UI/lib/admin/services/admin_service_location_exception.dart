class AdminServiceLocationException implements Exception {
  const AdminServiceLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
