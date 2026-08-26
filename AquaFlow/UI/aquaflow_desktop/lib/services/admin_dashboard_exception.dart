class AdminDashboardException implements Exception {
  const AdminDashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
