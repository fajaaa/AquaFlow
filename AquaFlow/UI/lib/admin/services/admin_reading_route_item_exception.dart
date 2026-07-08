class AdminReadingRouteItemException implements Exception {
  const AdminReadingRouteItemException(this.message);

  final String message;

  @override
  String toString() => message;
}
