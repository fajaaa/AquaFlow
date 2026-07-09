class PushNotificationException implements Exception {
  const PushNotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
