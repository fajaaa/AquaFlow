import 'admin_customer_profile_draft.dart';

class AdminUserDraft {
  const AdminUserDraft({
    required this.email,
    required this.phone,
    required this.userRoleId,
    required this.isActive,
    this.password,
    this.profile,
  });

  final String email;
  final String? password;
  final String phone;
  final int userRoleId;
  final bool isActive;
  // Set only when the selected role is Customer; carries the CustomerProfile
  // fields to send to `/CustomerProfiles` alongside the `/Users` request.
  final AdminCustomerProfileDraft? profile;

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

    return json;
  }
}
