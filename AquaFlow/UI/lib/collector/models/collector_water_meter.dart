/// A water meter search result for the collector search screen
/// (`WaterMeterResponse`). Carries the owning customer's name
/// (`CustomerFirstName`/`CustomerLastName`) and the meter's own address
/// (`SettlementName`/`Street`/`HouseNumber`) directly, so the search screen
/// needs no separate per-customer profile lookup.
class CollectorWaterMeter {
  const CollectorWaterMeter({
    required this.id,
    required this.serialNumber,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
    required this.status,
    required this.lastReading,
  });

  final int id;
  final String serialNumber;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;
  final String status;
  final double lastReading;

  /// Owning customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  /// "Street HouseNumber" joined; empty when neither is set.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  factory CollectorWaterMeter.fromJson(Map<String, dynamic> json) {
    return CollectorWaterMeter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serialNumber: (json['serialNumber'] ?? '') as String,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
      status: (json['status'] ?? '') as String,
      lastReading: (json['lastReading'] as num?)?.toDouble() ?? 0,
    );
  }
}
