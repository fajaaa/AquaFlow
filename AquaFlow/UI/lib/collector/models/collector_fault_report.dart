/// A fault report as returned by `/FaultReports` (`FaultReportResponse`) for
/// the collector's read+update surface. A collector no longer holds
/// `FaultReports.Manage`: the backend pins their reads to reports assigned to
/// their own `CollectorProfile` via `AssignedCollectorId` (same model as
/// `WaterMeterRequest`), so this list only ever contains the collector's own
/// assigned reports. Mirrors `AdminFaultReport`.
class CollectorFaultReport {
  const CollectorFaultReport({
    required this.id,
    required this.waterMeterId,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.settlementId,
    required this.settlementName,
    required this.title,
    required this.description,
    required this.status,
    required this.resolvedAt,
    required this.createdAt,
  });

  final int id;
  final int? waterMeterId;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int settlementId;
  final String settlementName;
  final String title;
  final String description;
  final String status;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  /// Owning customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  bool get isNew => status.toLowerCase() == 'new';
  bool get isAssigned => status.toLowerCase() == 'assigned';
  bool get isInProgress => status.toLowerCase() == 'inprogress';
  bool get isResolved => status.toLowerCase() == 'resolved';

  /// Next status in the (New/)Assigned -> InProgress -> Resolved chain, or
  /// null once Resolved (terminal - same precedent as
  /// `AdminFaultReportsScreen`'s status-advance action). A collector only ever
  /// sees assigned reports, but New is kept for completeness since the
  /// backend also allows Start straight from New.
  String? get nextStatus {
    if (isNew || isAssigned) return 'InProgress';
    if (isInProgress) return 'Resolved';
    return null;
  }

  factory CollectorFaultReport.fromJson(Map<String, dynamic> json) {
    return CollectorFaultReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt(),
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      resolvedAt: _date(json['resolvedAt']),
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
