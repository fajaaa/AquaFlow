/// The signed-in user's own account data as returned by `GET /Account/me`
/// (mirrors the backend `UserResponse`). Every role has these fields - they live
/// on the `User` entity - which is why the account edit applies to all users.
///
/// Only [email] and [phone] are editable; they are sent back with [toUpdateJson]
/// for `PUT /Account/me`. [userRole] and [isActive] are read-only context (a user
/// cannot change their own role or active state from here).
class AccountDetails {
  const AccountDetails({
    required this.id,
    required this.email,
    required this.phone,
    required this.userRole,
    required this.isActive,
  });

  final int id;
  final String email;
  final String phone;
  final String userRole;
  final bool isActive;

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      userRole: (json['userRole'] ?? '') as String,
      isActive: json['isActive'] == true,
    );
  }

  /// Body for `PUT /Account/me`. Only the self-editable fields are sent; the
  /// backend `AccountUpdateRequest` carries no id (it comes from the JWT).
  Map<String, dynamic> toUpdateJson() => {
        'email': email,
        'phone': phone,
      };
}
