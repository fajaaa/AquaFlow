/// The signed-in user's own account data as returned by `GET /Account/me`
/// (mirrors the backend `UserResponse`). Every role has these fields - they live
/// on the `User` entity - which is why the account edit applies to all users.
///
/// [email], [phone], [firstName] and [lastName] are editable and sent back with
/// [toUpdateJson] for `PUT /Account/me`. [userRole] and [isActive] are read-only
/// context (a user cannot change their own role or active state from here).
///
/// [firstName]/[lastName] are only meaningful for roles without a
/// CustomerProfile (Admin/Collector) - the backend `UserResponse` mapping
/// sources them from `CustomerProfile.FirstName/LastName` when a profile
/// exists, falling back to `User.FirstName/LastName` otherwise. Editing them
/// here writes straight to `User.FirstName/LastName`, same as `UsersController`
/// does when another admin edits an admin/collector account.
class AccountDetails {
  const AccountDetails({
    required this.id,
    required this.email,
    required this.phone,
    required this.userRole,
    required this.isActive,
    this.firstName = '',
    this.lastName = '',
  });

  final int id;
  final String email;
  final String phone;
  final String userRole;
  final bool isActive;
  final String firstName;
  final String lastName;

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      userRole: (json['userRole'] ?? '') as String,
      isActive: json['isActive'] == true,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
    );
  }

  /// Body for `PUT /Account/me`. The backend `AccountUpdateRequest` carries no
  /// id (it comes from the JWT).
  Map<String, dynamic> toUpdateJson() => {
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
      };
}
