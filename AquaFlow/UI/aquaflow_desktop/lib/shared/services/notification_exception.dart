class NotificationException implements Exception {
  const NotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
