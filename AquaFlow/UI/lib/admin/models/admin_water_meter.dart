class AdminWaterMeter {
  const AdminWaterMeter({
    required this.id,
    required this.serialNumber,
    required this.serviceLocationId,
    required this.serviceLocationAddress,
    required this.installedAt,
    required this.status,
    required this.initialReading,
    required this.lastReading,
  });

  final int id;
  final String serialNumber;
  final int serviceLocationId;
  final String serviceLocationAddress;
  final DateTime? installedAt;
  final String status;
  final double initialReading;
  final double lastReading;

  factory AdminWaterMeter.fromJson(Map<String, dynamic> json) {
    return AdminWaterMeter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serialNumber: (json['serialNumber'] ?? '') as String,
      serviceLocationId: (json['serviceLocationId'] as num?)?.toInt() ?? 0,
      serviceLocationAddress: (json['serviceLocationAddress'] ?? '') as String,
      installedAt: _date(json['installedAt']),
      status: (json['status'] ?? '') as String,
      initialReading: (json['initialReading'] as num?)?.toDouble() ?? 0,
      lastReading: (json['lastReading'] as num?)?.toDouble() ?? 0,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
