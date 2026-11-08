class AdminConsumptionAlert {
  const AdminConsumptionAlert({
    required this.id,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.waterMeterId,
    required this.waterMeterSerialNumber,
    required this.alertType,
    required this.measuredValue,
    required this.thresholdValue,
    this.expectedValue,
    this.expectedLowerBound,
    this.expectedUpperBound,
    required this.message,
    required this.isResolved,
    required this.resolvedAt,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int waterMeterId;
  final String waterMeterSerialNumber;
  final String alertType;
  final double measuredValue;
  final double thresholdValue;

  /// Forecast model's expectation and its 95 % interval; null for alerts
  /// raised before the model existed or without enough history.
  final double? expectedValue;
  final double? expectedLowerBound;
  final double? expectedUpperBound;
  final String message;
  final bool isResolved;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  String get customerFullName => [
    customerFirstName.trim(),
    customerLastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  factory AdminConsumptionAlert.fromJson(Map<String, dynamic> json) {
    return AdminConsumptionAlert(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt() ?? 0,
      waterMeterSerialNumber:
          (json['waterMeterSerialNumber'] ?? '') as String,
      alertType: (json['alertType'] ?? '') as String,
      measuredValue: (json['measuredValue'] as num?)?.toDouble() ?? 0,
      thresholdValue: (json['thresholdValue'] as num?)?.toDouble() ?? 0,
      expectedValue: (json['expectedValue'] as num?)?.toDouble(),
      expectedLowerBound: (json['expectedLowerBound'] as num?)?.toDouble(),
      expectedUpperBound: (json['expectedUpperBound'] as num?)?.toDouble(),
      message: (json['message'] ?? '') as String,
      isResolved: (json['isResolved'] as bool?) ?? false,
      resolvedAt: _date(json['resolvedAt']),
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
