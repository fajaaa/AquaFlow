/// A customer's profile as returned by `GET /CustomerProfiles`
/// (mirrors the backend `CustomerProfileResponse`). Only the fields the
/// account screen and mobile customer/collector screens need are decoded -
/// first/last name and the Settlement/Street/HouseNumber address, since
/// `CustomerProfile` is the only place either lives (not on `User`).
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
  });

  final int? id;
  final int? userId;
  final String firstName;
  final String lastName;
  final int? settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;

  /// First and last name joined; empty when the profile carries no name.
  String get fullName => '$firstName $lastName'.trim();

  /// "Street HouseNumber" joined; empty when neither is set.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt(),
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
    );
  }
}
