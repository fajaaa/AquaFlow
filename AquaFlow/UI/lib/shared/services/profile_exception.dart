/// Raised by `ProfileService` when a profile cannot be loaded. Carries a
/// message that is safe to display to the user.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => 'ProfileException: $message';
}
