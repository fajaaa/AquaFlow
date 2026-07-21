class CustomerSupportTicketException implements Exception {
  const CustomerSupportTicketException(this.message);

  final String message;

  @override
  String toString() => message;
}
