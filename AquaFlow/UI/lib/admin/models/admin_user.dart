class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.userRoleId,
    required this.userRole,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String phone;
  final int userRoleId;
  final String userRole;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      userRoleId: (json['userRoleId'] as num?)?.toInt() ?? 0,
      userRole: (json['userRole'] ?? '') as String,
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
