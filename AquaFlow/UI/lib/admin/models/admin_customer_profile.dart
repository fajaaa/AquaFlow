/// A customer's profile as returned by `GET /CustomerProfiles?UserId=`.
/// Fetched by the admin Users editor so it can pre-fill and PATCH the
/// existing profile instead of creating a duplicate one.
class AdminCustomerProfile {
  const AdminCustomerProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.customerCode,
    required this.defaultLanguage,
    required this.theme,
  });

  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String customerCode;
  final String defaultLanguage;
  final String theme;

  factory AdminCustomerProfile.fromJson(Map<String, dynamic> json) {
    return AdminCustomerProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      customerCode: (json['customerCode'] ?? '') as String,
      defaultLanguage: (json['defaultLanguage'] ?? 'bs') as String,
      theme: (json['theme'] ?? 'light') as String,
    );
  }
}
