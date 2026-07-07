class AdminCityException implements Exception {
  const AdminCityException(this.message);

  final String message;

  @override
  String toString() => message;
}
