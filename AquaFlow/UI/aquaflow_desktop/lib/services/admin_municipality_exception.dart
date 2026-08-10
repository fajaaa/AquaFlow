class AdminMunicipalityException implements Exception {
  const AdminMunicipalityException(this.message);

  final String message;

  @override
  String toString() => message;
}
