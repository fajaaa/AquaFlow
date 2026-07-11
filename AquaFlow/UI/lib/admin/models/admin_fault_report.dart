/// A fault report as returned by `/FaultReports` (`FaultReportResponse`).
/// Carries the owning customer's name (`CustomerFirstName`/`CustomerLastName`,
/// flattened from the linked `CustomerProfile`) and the report's own
/// `SettlementName` (flattened from the linked `Settlement` - a `FaultReport`
/// carries its own `SettlementId`, not one derived from the customer's
/// profile) directly, same pattern as `AdminInvoice`/`AdminWaterMeter`.
class AdminFaultReport {
  const AdminFaultReport({
    required this.id,
    required this.reportedById,
    required this.waterMeterId,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.settlementId,
    required this.settlementName,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.status,
    required this.assignedCollectorId,
    required this.assignedCollectorEmployeeCode,
    required this.resolvedAt,
    required this.createdAt,
  });

  final int id;
  final int reportedById;
  final int? waterMeterId;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int settlementId;
  final String settlementName;
  final String title;
  final String description;
  final String? photoUrl;
  final String status;

  /// The collector the report is assigned to (`AssignedCollectorId` +
  /// `AssignedCollectorEmployeeCode`, flattened from the linked
  /// `CollectorProfile`); both null while the report is unassigned.
  final int? assignedCollectorId;
  final String? assignedCollectorEmployeeCode;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  /// Owning customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory AdminFaultReport.fromJson(Map<String, dynamic> json) {
    return AdminFaultReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reportedById: (json['reportedById'] as num?)?.toInt() ?? 0,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt(),
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      photoUrl: json['photoUrl'] as String?,
      status: (json['status'] ?? '') as String,
      assignedCollectorId: (json['assignedCollectorId'] as num?)?.toInt(),
      assignedCollectorEmployeeCode:
          json['assignedCollectorEmployeeCode'] as String?,
      resolvedAt: _date(json['resolvedAt']),
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
