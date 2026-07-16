class AdminActivityLogException implements Exception {
  const AdminActivityLogException(this.message);

  final String message;

  @override
  String toString() => message;
}
