class AdminTariffException implements Exception {
  const AdminTariffException(this.message);

  final String message;

  @override
  String toString() => message;
}
