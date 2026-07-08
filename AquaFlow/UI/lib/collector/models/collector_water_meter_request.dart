/// A water meter request assigned to the signed-in collector
/// (`WaterMeterRequestResponse`). Carries the requested address
/// (`SettlementId`/`SettlementName`/`Street`/`HouseNumber`) and the requesting
/// customer's contact (`CustomerFirstName`/`CustomerLastName`/`CustomerPhone`)
/// directly, so the collector no longer needs a separate `ProfileService`
/// lookup by `customerId` to show where the meter should go or how to reach the
/// customer.
class CollectorWaterMeterRequest {
  const CollectorWaterMeterRequest({
    required this.id,
    required this.customerId,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
  });

  final int id;
  final int customerId;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final int? settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;
  final String customerFirstName;
  final String customerLastName;
  final String? customerPhone;

  bool get isAssigned => status.toLowerCase() == 'assigned';

  /// "Street HouseNumber" joined; empty when neither is set.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  /// Requesting customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory CollectorWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return CollectorWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      note: json['note'] as String?,
      createdAt: _date(json['createdAt']),
      settlementId: (json['settlementId'] as num?)?.toInt(),
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      customerPhone: json['customerPhone'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
