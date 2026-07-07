/// A water meter request assigned to the signed-in collector
/// (`WaterMeterRequestResponse`). Carries no location - `WaterMeterRequest`
/// has none anymore; the requesting customer's naselje/adresa is looked up
/// separately by `customerId` (see `CollectorWaterMeterRequestsScreen`).
class CollectorWaterMeterRequest {
  const CollectorWaterMeterRequest({
    required this.id,
    required this.customerId,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String status;
  final String? note;
  final DateTime? createdAt;

  bool get isAssigned => status.toLowerCase() == 'assigned';

  factory CollectorWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return CollectorWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      note: json['note'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
