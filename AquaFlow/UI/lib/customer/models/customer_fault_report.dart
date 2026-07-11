/// A customer's fault report (`FaultReportResponse`). Status values mirror the
/// backend `FaultReport.Status` column (New/InProgress/Resolved, currently a
/// plain string column - not a state machine like WaterMeterRequest/Invoice).
class CustomerFaultReport {
  const CustomerFaultReport({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.waterMeterId,
    required this.createdAt,
    required this.resolvedAt,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int? waterMeterId;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  /// Only a New report may still have photos removed by its owner (mirrors
  /// FaultReportsController.DeletePhoto's self-service status gate).
  bool get isNew => status.toLowerCase() == 'new';

  factory CustomerFaultReport.fromJson(Map<String, dynamic> json) {
    return CustomerFaultReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      priority: (json['priority'] ?? '') as String,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt(),
      createdAt: _date(json['createdAt']),
      resolvedAt: _date(json['resolvedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
