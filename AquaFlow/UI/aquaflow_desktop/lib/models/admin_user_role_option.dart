class AdminUserRoleOption {
  const AdminUserRoleOption({required this.id, required this.name});

  final int id;
  final String name;

  factory AdminUserRoleOption.fromJson(Map<String, dynamic> json) {
    return AdminUserRoleOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
    );
  }
}
