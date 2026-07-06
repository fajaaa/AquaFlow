class AdminCollectorProfile {
  const AdminCollectorProfile({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.assignedAreaId,
  });

  final int id;
  final int userId;
  final String employeeCode;
  final int? assignedAreaId;

  String get label {
    final code = employeeCode.trim();
    if (code.isNotEmpty) return code;
    return 'Collector #$id';
  }

  factory AdminCollectorProfile.fromJson(Map<String, dynamic> json) {
    return AdminCollectorProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      employeeCode: (json['employeeCode'] ?? '') as String,
      assignedAreaId: (json['assignedAreaId'] as num?)?.toInt(),
    );
  }
}
