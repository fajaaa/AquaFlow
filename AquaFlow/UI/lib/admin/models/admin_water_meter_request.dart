class AdminWaterMeterRequest {
  const AdminWaterMeterRequest({
    required this.id,
    required this.customerId,
    required this.status,
    required this.assignedCollectorId,
    required this.resultingWaterMeterId,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String status;
  final int? assignedCollectorId;
  final int? resultingWaterMeterId;
  final String? note;
  final DateTime? createdAt;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAssigned => status.toLowerCase() == 'assigned';

  factory AdminWaterMeterRequest.fromJson(Map<String, dynamic> json) {
    return AdminWaterMeterRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '') as String,
      assignedCollectorId: (json['assignedCollectorId'] as num?)?.toInt(),
      resultingWaterMeterId: (json['resultingWaterMeterId'] as num?)?.toInt(),
      note: json['note'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
