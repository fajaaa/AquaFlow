class ActivityLogItem {
  const ActivityLogItem({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.description,
    required this.ipAddress,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String eventType;
  final String? description;
  final String? ipAddress;
  final DateTime? createdAt;

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      eventType: json['eventType'] as String? ?? '',
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
