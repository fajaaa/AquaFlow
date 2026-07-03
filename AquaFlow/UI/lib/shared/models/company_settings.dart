/// Company-wide settings as returned by `GET /CompanySettings`
/// (mirrors the backend `CompanySettingsResponse`). There is a single settings
/// row; an admin edits it from the account screen and it is sent back with
/// [toUpdateJson] for `PUT /CompanySettings/{id}` (the update request carries no
/// id - the id travels in the URL).
class CompanySettings {
  const CompanySettings({
    required this.id,
    required this.companyName,
    required this.address,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.bankAccount,
    required this.logoUrl,
    required this.defaultLanguage,
    required this.defaultCurrency,
  });

  final int id;
  final String companyName;
  final String address;
  final String phone;
  final String email;
  final String taxNumber;
  final String bankAccount;
  final String? logoUrl;
  final String defaultLanguage;
  final String defaultCurrency;

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyName: (json['companyName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      taxNumber: (json['taxNumber'] ?? '') as String,
      bankAccount: (json['bankAccount'] ?? '') as String,
      logoUrl: json['logoUrl'] as String?,
      defaultLanguage: (json['defaultLanguage'] ?? 'bs') as String,
      defaultCurrency: (json['defaultCurrency'] ?? 'BAM') as String,
    );
  }

  /// Body for `PUT /CompanySettings/{id}`. The id is not included because the
  /// backend `CompanySettingsUpdateRequest` has no id field.
  Map<String, dynamic> toUpdateJson() => {
        'companyName': companyName,
        'address': address,
        'phone': phone,
        'email': email,
        'taxNumber': taxNumber,
        'bankAccount': bankAccount,
        'logoUrl': logoUrl,
        'defaultLanguage': defaultLanguage,
        'defaultCurrency': defaultCurrency,
      };
}
