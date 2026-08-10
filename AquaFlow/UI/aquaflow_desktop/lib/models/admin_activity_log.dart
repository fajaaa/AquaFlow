class AdminActivityLog {
  const AdminActivityLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.eventType,
    required this.description,
    required this.ipAddress,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String userEmail;
  final String eventType;
  final String? description;
  final String? ipAddress;
  final DateTime? createdAt;

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userEmail: (json['userEmail'] ?? '') as String,
      eventType: (json['eventType'] ?? '') as String,
      description: json['description'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
