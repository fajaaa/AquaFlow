/// A water meter request as returned by `/WaterMeterRequests`
/// (`WaterMeterRequestResponse`). Carries the requested address
/// (`SettlementId`/`SettlementName`/`Street`/`HouseNumber`) and the requesting
/// customer's contact (`CustomerFirstName`/`CustomerLastName`/`CustomerPhone`,
/// flattened from the linked `CustomerProfile` and its `User`) directly, so the
/// admin list can show where the meter should go and who to contact without a
/// per-customer profile lookup.
class AdminWaterMeterRequest {
  const AdminWaterMeterRequest({
    required this.id,
    required this.customerId,
    required this.status,
    required this.assignedCollectorId,
    required this.resultingWaterMeterId,
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
  final int? assignedCollectorId;
  final int? resultingWaterMeterId;
  final String? note;
  final DateTime? createdAt;
  final int settlementId;
  final String settlementName;
  final String street;
  final String houseNumber;
  final String customerFirstName;
  final String customerLastName;
  final String? customerPhone;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAssigned => status.toLowerCase() == 'assigned';

  /// "Street HouseNumber" joined; empty when neither is set.
  String get address => [
    street.trim(),
    houseNumber.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// Requesting customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory AdminWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return AdminWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      assignedCollectorId: (json['assignedCollectorId'] as num?)?.toInt(),
      resultingWaterMeterId: (json['resultingWaterMeterId'] as num?)?.toInt(),
      note: json['note'] as String?,
      createdAt: _date(json['createdAt']),
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      street: (json['street'] ?? '') as String,
      houseNumber: (json['houseNumber'] ?? '') as String,
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
