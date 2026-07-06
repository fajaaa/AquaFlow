class AdminCollectorProfile {
  const AdminCollectorProfile({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.assignedAreaId,
    required this.assignedAreaName,
    required this.isActive,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  final int id;
  final int userId;
  final String employeeCode;
  final int? assignedAreaId;
  final String assignedAreaName;
  final bool isActive;
  final DateTime? createdAt;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  String get label {
    final name = fullName;
    if (name.isNotEmpty) return name;

    final emailText = email.trim();
    if (emailText.isNotEmpty) return emailText;

    final code = employeeCode.trim();
    if (code.isNotEmpty) return code;

    return 'Inkasant #$id';
  }

  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    return [first, last].where((part) => part.isNotEmpty).join(' ');
  }

  String get areaLabel {
    final area = assignedAreaName.trim();
    if (area.isNotEmpty) return area;
    final areaId = assignedAreaId;
    return areaId == null ? '-' : 'Područje #$areaId';
  }

  factory AdminCollectorProfile.fromJson(Map<String, dynamic> json) {
    return AdminCollectorProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      employeeCode: (json['employeeCode'] ?? '') as String,
      assignedAreaId: (json['assignedAreaId'] as num?)?.toInt(),
      assignedAreaName: (json['assignedAreaName'] ?? '') as String,
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: _date(json['createdAt']),
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
