class AdminRoleException implements Exception {
  const AdminRoleException(this.message);

  final String message;

  @override
  String toString() => message;
}
