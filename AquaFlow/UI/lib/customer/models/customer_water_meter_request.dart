/// A customer's request for a new water meter (`WaterMeterRequestResponse`).
/// Status values mirror the backend `WaterMeterRequestStatus` constants.
class CustomerWaterMeterRequest {
  const CustomerWaterMeterRequest({
    required this.id,
    required this.serviceLocationId,
    required this.serviceLocationAddress,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int serviceLocationId;
  final String serviceLocationAddress;
  final String status;
  final String? note;
  final DateTime? createdAt;

  /// Only a Pending request can still be cancelled by the requester.
  bool get isPending => status.toLowerCase() == 'pending';

  factory CustomerWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return CustomerWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceLocationId: (json['serviceLocationId'] as num?)?.toInt() ?? 0,
      serviceLocationAddress: (json['serviceLocationAddress'] ?? '') as String,
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
