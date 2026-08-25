class AdminRecommendation {
  const AdminRecommendation({
    required this.id,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.waterMeterId,
    required this.waterMeterSerialNumber,
    required this.type,
    required this.message,
    required this.reason,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int? waterMeterId;
  final String waterMeterSerialNumber;
  final String type;
  final String message;
  final String reason;
  final bool isRead;
  final DateTime? createdAt;

  String get customerFullName => [
    customerFirstName.trim(),
    customerLastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  factory AdminRecommendation.fromJson(Map<String, dynamic> json) {
    return AdminRecommendation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt(),
      waterMeterSerialNumber:
          (json['waterMeterSerialNumber'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      reason: (json['reason'] ?? '') as String,
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
