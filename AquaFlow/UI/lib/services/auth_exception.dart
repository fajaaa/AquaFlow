/// A user-facing authentication error carrying a message safe to show in the UI.
///
/// [AuthService] converts backend `{ message, errors }` bodies and transport
/// failures into this type so the UI never has to parse HTTP details itself.
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
