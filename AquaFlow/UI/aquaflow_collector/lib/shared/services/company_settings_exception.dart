/// Raised by `CompanySettingsService` when the company settings cannot be
/// loaded or saved. Carries a message that is safe to display to the user.
class CompanySettingsException implements Exception {
  const CompanySettingsException(this.message);

  final String message;

  @override
  String toString() => 'CompanySettingsException: $message';
}
