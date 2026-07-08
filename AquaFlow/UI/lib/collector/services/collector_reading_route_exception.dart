class CollectorReadingRouteException implements Exception {
  const CollectorReadingRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
