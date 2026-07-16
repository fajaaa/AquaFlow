class ActivityLogException implements Exception {
  const ActivityLogException(this.message);

  final String message;

  @override
  String toString() => message;
}
