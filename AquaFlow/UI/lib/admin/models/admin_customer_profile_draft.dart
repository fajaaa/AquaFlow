/// Editable CustomerProfile fields, carried inside [AdminUserDraft] for any
/// role (not just Customer). Sent to `/CustomerProfiles` (POST or PATCH)
/// alongside the `/Users` request. `customerCode` is not included - the
/// backend always assigns/keeps it (CustomerProfileService).
class AdminCustomerProfileDraft {
  const AdminCustomerProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.defaultLanguage,
    required this.theme,
    this.settlementId,
    this.street,
    this.houseNumber,
  });

  final String firstName;
  final String lastName;
  final String defaultLanguage;
  final String theme;
  final int? settlementId;
  final String? street;
  final String? houseNumber;

  Map<String, Object?> toJson(int userId) {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'defaultLanguage': defaultLanguage,
      'theme': theme,
      'settlementId': settlementId,
      'street': street,
      'houseNumber': houseNumber,
    };
  }
}
