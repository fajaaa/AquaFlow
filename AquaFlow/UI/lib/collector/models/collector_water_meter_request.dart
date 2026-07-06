class CollectorWaterMeterRequest {
  const CollectorWaterMeterRequest({
    required this.id,
    required this.customerId,
    required this.serviceLocationId,
    required this.serviceLocationAddress,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final int serviceLocationId;
  final String serviceLocationAddress;
  final String status;
  final String? note;
  final DateTime? createdAt;

  bool get isAssigned => status.toLowerCase() == 'assigned';

  factory CollectorWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return CollectorWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
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
