class AdminReadingRouteItem {
  const AdminReadingRouteItem({
    required this.id,
    required this.readingRouteId,
    required this.waterMeterId,
    required this.sortOrder,
    required this.status,
    required this.completedAt,
    required this.waterMeterSerialNumber,
    required this.settlementName,
    required this.customerFirstName,
    required this.customerLastName,
  });

  final int id;
  final int readingRouteId;
  final int waterMeterId;
  final int sortOrder;
  final String status;
  final DateTime? completedAt;
  final String waterMeterSerialNumber;
  final String settlementName;
  final String customerFirstName;
  final String customerLastName;

  /// Customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory AdminReadingRouteItem.fromJson(Map<String, dynamic> json) {
    return AdminReadingRouteItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      readingRouteId: (json['readingRouteId'] as num?)?.toInt() ?? 0,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      completedAt: _date(json['completedAt']),
      waterMeterSerialNumber: (json['waterMeterSerialNumber'] ?? '') as String,
      settlementName: (json['settlementName'] ?? '') as String,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
