/// Raised by `PreferencesApiService` when the signed-in user's preferences
/// cannot be loaded or saved. Carries a message that is safe to display to
/// the user.
class PreferencesException implements Exception {
  const PreferencesException(this.message);

  final String message;

  @override
  String toString() => 'PreferencesException: $message';
}
