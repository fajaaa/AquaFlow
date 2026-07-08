class AdminReadingRouteException implements Exception {
  const AdminReadingRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
