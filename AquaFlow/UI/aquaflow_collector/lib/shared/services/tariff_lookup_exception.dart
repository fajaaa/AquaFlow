/// Raised by [TariffLookupService] when the active-tariff list cannot be
/// loaded. Carries a message that is safe to display to the user.
class TariffLookupException implements Exception {
  const TariffLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
