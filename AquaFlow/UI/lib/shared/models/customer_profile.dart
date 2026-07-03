/// A customer's profile as returned by `GET /CustomerProfiles`
/// (mirrors the backend `CustomerProfileResponse`). Only the fields the account
/// screen needs are decoded - the customer profile is the only place a user's
/// first/last name is stored, so it is fetched to show a real name.
class CustomerProfile {
  const CustomerProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  final int? userId;
  final String firstName;
  final String lastName;

  /// First and last name joined; empty when the profile carries no name.
  String get fullName => '$firstName $lastName'.trim();

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      userId: (json['userId'] as num?)?.toInt(),
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
    );
  }
}
