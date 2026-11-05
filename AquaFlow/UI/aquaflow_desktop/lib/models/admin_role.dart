class AdminRole {
  const AdminRole({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.isSystem,
  });

  final int id;
  final String name;
  final String description;
  final bool isActive;
  final bool isSystem;

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      isActive: (json['isActive'] as bool?) ?? false,
      isSystem: (json['isSystem'] as bool?) ?? false,
    );
  }
}

class AdminRoleDraft {
  const AdminRoleDraft({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
  final bool isActive;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'isActive': isActive,
  };
}

class AdminPermission {
  const AdminPermission({
    required this.id,
    required this.code,
    required this.name,
    required this.module,
    required this.description,
    required this.isActive,
    required this.isSystem,
  });

  final int id;
  final String code;
  final String name;
  final String module;
  final String description;
  final bool isActive;
  final bool isSystem;

  factory AdminPermission.fromJson(Map<String, dynamic> json) {
    return AdminPermission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      module: (json['module'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      isActive: (json['isActive'] as bool?) ?? false,
      isSystem: (json['isSystem'] as bool?) ?? false,
    );
  }
}

class AdminPermissionDraft {
  const AdminPermissionDraft({
    required this.code,
    required this.name,
    required this.module,
    required this.description,
    required this.isActive,
  });

  final String code;
  final String name;
  final String module;
  final String description;
  final bool isActive;

  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'module': module,
    'description': description,
    'isActive': isActive,
  };
}

/// One (role, permission) assignment row; [id] is what DELETE needs.
class AdminRolePermission {
  const AdminRolePermission({
    required this.id,
    required this.userRoleId,
    required this.permissionId,
  });

  final int id;
  final int userRoleId;
  final int permissionId;

  factory AdminRolePermission.fromJson(Map<String, dynamic> json) {
    return AdminRolePermission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userRoleId: (json['userRoleId'] as num?)?.toInt() ?? 0,
      permissionId: (json['permissionId'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPage<T> {
  const AdminPage({required this.items, required this.totalCount});

  final List<T> items;
  final int totalCount;
}
