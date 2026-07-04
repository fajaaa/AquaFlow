/// Editable CustomerProfile fields, carried inside [AdminUserDraft] when the
/// user's role is Customer. Sent to `/CustomerProfiles` (POST or PATCH)
/// alongside the `/Users` request.
class AdminCustomerProfileDraft {
  const AdminCustomerProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.customerCode,
    required this.defaultLanguage,
    required this.theme,
  });

  final String firstName;
  final String lastName;
  final String customerCode;
  final String defaultLanguage;
  final String theme;

  Map<String, Object?> toJson(int userId) {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'customerCode': customerCode,
      'defaultLanguage': defaultLanguage,
      'theme': theme,
    };
  }
}
