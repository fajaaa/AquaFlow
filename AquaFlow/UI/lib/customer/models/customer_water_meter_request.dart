/// A customer's request for a new water meter (`WaterMeterRequestResponse`).
/// Status values mirror the backend `WaterMeterRequestStatus` constants.
/// Carries the requested address (`SettlementId`/`SettlementName`/`Street`/
/// `HouseNumber`) entered when the request was filed; the resulting meter is
/// registered against that address (a collector may correct it on site).
class CustomerWaterMeterRequest {
  const CustomerWaterMeterRequest({
    required this.id,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
  });

  final int id;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final int? settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;

  /// Only a Pending request can still be cancelled by the requester.
  bool get isPending => status.toLowerCase() == 'pending';

  /// "Street HouseNumber" joined; empty when neither is set.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  factory CustomerWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return CustomerWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      note: json['note'] as String?,
      createdAt: _date(json['createdAt']),
      settlementId: (json['settlementId'] as num?)?.toInt(),
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
