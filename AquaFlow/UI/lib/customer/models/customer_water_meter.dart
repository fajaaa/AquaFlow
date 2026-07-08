class CustomerWaterMeter {
  const CustomerWaterMeter({
    required this.id,
    required this.serialNumber,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
    required this.installedAt,
    required this.status,
    required this.initialReading,
    required this.lastReading,
  });

  final int id;
  final String serialNumber;
  final int settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;
  final DateTime? installedAt;
  final String status;
  final double initialReading;
  final double lastReading;

  /// "Street HouseNumber" joined; empty when neither is set. This is the
  /// meter's own address, not the customer's profile address.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  factory CustomerWaterMeter.fromJson(Map<String, dynamic> json) {
    return CustomerWaterMeter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serialNumber: (json['serialNumber'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
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
