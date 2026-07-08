class AdminReadingRoute {
  const AdminReadingRoute({
    required this.id,
    required this.name,
    required this.scheduledDate,
    required this.status,
    required this.collectorId,
    required this.collectorFirstName,
    required this.collectorLastName,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime? scheduledDate;
  final String status;
  final int? collectorId;
  final String collectorFirstName;
  final String collectorLastName;
  final DateTime? createdAt;

  /// Assigned collector's first and last name joined; "Nedodijeljeno" when
  /// the route has no collector yet.
  String get collectorFullName {
    if (collectorId == null) return 'Nedodijeljeno';
    return '$collectorFirstName $collectorLastName'.trim();
  }

  factory AdminReadingRoute.fromJson(Map<String, dynamic> json) {
    return AdminReadingRoute(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      scheduledDate: _date(json['scheduledDate']),
      status: (json['status'] ?? '') as String,
      collectorId: (json['collectorId'] as num?)?.toInt(),
      collectorFirstName: (json['collectorFirstName'] ?? '') as String,
      collectorLastName: (json['collectorLastName'] ?? '') as String,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
