class AdminUserDraft {
  const AdminUserDraft({
    required this.email,
    required this.phone,
    required this.userRoleId,
    required this.isActive,
    this.password,
  });

  final String email;
  final String? password;
  final String phone;
  final int userRoleId;
  final bool isActive;

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
