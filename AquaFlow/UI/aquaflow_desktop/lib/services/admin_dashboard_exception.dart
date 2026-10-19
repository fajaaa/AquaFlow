class AdminDashboardException implements Exception {
  const AdminDashboardException(this.message, {this.isForbidden = false});

  final String message;

  /// True when the API answered 403: the signed-in token lacks
  /// `Dashboard.Read` (typically an admin token issued before that
  /// permission was seeded - a fresh login picks it up).
  final bool isForbidden;

  @override
  String toString() => message;
}
