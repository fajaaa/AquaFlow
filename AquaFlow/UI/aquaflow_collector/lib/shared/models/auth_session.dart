import 'package:jwt_decoder/jwt_decoder.dart';

/// The authenticated user, decoded from the access-token JWT.
///
/// Claim names come from the backend
/// (AquaFlow.WebAPI/Services/AccessManager/ClaimNames.cs):
/// `Id`, `Email`, `UserRole`, `IsActive`, and zero or more `Permission` claims.
/// When a user's role has a single permission the `Permission` claim decodes to
/// a plain string; with several it decodes to a list - both are normalised here.
class AuthSession {
  const AuthSession({
    required this.id,
    required this.email,
    required this.userRole,
    required this.isActive,
    required this.permissions,
    required this.expiresAt,
  });

  final int? id;
  final String email;
  final String userRole;
  final bool isActive;
  final List<String> permissions;
  final DateTime expiresAt;

  bool hasPermission(String code) =>
      permissions.any((p) => p.toLowerCase() == code.toLowerCase());

  /// Builds a session from a raw JWT access token. Throws [FormatException]
  /// (via jwt_decoder) if the token is not a valid JWT.
  factory AuthSession.fromAccessToken(String accessToken) {
    final Map<String, dynamic> claims = JwtDecoder.decode(accessToken);
    return AuthSession(
      id: int.tryParse('${claims['Id']}'),
      email: (claims['Email'] ?? '') as String,
      userRole: (claims['UserRole'] ?? '') as String,
      isActive: _parseBool(claims['IsActive']),
      permissions: _parsePermissions(claims['Permission']),
      expiresAt: JwtDecoder.getExpirationDate(accessToken),
    );
  }

  static bool _parseBool(Object? value) =>
      value is bool ? value : '$value'.toLowerCase() == 'true';

  static List<String> _parsePermissions(Object? value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => '$e').toList();
    return ['$value'];
  }
}
