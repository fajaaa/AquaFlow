/// A customer's profile as returned by `GET /CustomerProfiles`. Fetched by
/// the admin Users editor (by `UserId`) so it can pre-fill and PATCH the
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
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
  });

  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String customerCode;
  final String defaultLanguage;
  final String theme;
  final int? settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;

  /// "First Last (CUS-0001)" for dropdown display; falls back to the code or
  /// profile id when the name is blank.
  String get label {
    final name = '$firstName $lastName'.trim();
    final code = customerCode.trim();
    if (name.isEmpty) return code.isEmpty ? 'Kupac #$id' : code;
    return code.isEmpty ? name : '$name ($code)';
  }

  factory AdminCustomerProfile.fromJson(Map<String, dynamic> json) {
    return AdminCustomerProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      customerCode: (json['customerCode'] ?? '') as String,
      defaultLanguage: (json['defaultLanguage'] ?? 'bs') as String,
      theme: (json['theme'] ?? 'light') as String,
      settlementId: (json['settlementId'] as num?)?.toInt(),
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
    );
  }
}
