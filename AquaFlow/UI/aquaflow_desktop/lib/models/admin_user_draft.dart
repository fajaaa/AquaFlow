import 'admin_customer_profile_draft.dart';

class AdminUserDraft {
  const AdminUserDraft({
    required this.email,
    required this.phone,
    required this.userRoleId,
    required this.isActive,
    this.password,
    this.profile,
    this.firstName,
    this.lastName,
  });

  final String email;
  final String? password;
  final String phone;
  final int userRoleId;
  final bool isActive;
  // Set when the admin entered a first/last name for a role with a
  // CustomerProfile (Customer); carries the CustomerProfile fields to send
  // to `/CustomerProfiles` alongside the `/Users` request.
  final AdminCustomerProfileDraft? profile;
  // Set instead of [profile] for a role without a CustomerProfile (Admin) -
  // sent straight on the `/Users` request onto `User.FirstName/LastName`.
  final String? firstName;
  final String? lastName;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'email': email,
      'phone': phone,
      'userRoleId': userRoleId,
      'isActive': isActive,
    };

    final pwd = password;
    if (pwd != null && pwd.isNotEmpty) {
      json['password'] = pwd;
    }
    if (firstName != null) {
      json['firstName'] = firstName;
    }
    if (lastName != null) {
      json['lastName'] = lastName;
    }

    return json;
  }
}
