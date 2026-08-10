/// Raised by `AccountService` when the signed-in user's account data cannot be
/// loaded or saved. Carries a message that is safe to display to the user.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => 'AccountException: $message';
}
