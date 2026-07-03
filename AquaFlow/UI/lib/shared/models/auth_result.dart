/// The token pair returned by `POST /Access/login` and `POST /Access/refresh`.
///
/// Mirrors the backend `UserLoginResponse`
/// (AquaFlow.Model/Access/UserLoginResponse.cs).
class AuthResult {
  const AuthResult({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: (json['accessToken'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
    );
  }
}
