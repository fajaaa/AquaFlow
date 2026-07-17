class AdminSupportTicketException implements Exception {
  const AdminSupportTicketException(this.message);

  final String message;

  @override
  String toString() => message;
}
