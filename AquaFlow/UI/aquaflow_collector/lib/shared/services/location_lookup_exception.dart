/// Raised by [LocationLookupService] when the City/Municipality/Settlement
/// lookups cannot be loaded. Carries a message that is safe to display to the
/// user.
class LocationLookupException implements Exception {
  const LocationLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
