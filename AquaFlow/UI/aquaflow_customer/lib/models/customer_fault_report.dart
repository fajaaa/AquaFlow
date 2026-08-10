/// A customer's fault report (`FaultReportResponse`). Status values mirror the
/// backend `FaultReport.Status` column (New/Assigned/InProgress/Resolved).
/// The report carries its own location (settlement + optional street/house
/// number), independent of the reporter's profile.
class CustomerFaultReport {
  const CustomerFaultReport({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.waterMeterId,
    required this.settlementId,
    required this.settlementName,
    required this.street,
    required this.houseNumber,
    required this.createdAt,
    required this.resolvedAt,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final int? waterMeterId;
  final int settlementId;
  final String settlementName;
  final String? street;
  final String? houseNumber;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  /// Only a New report may still have photos removed by its owner (mirrors
  /// FaultReportsController.DeletePhoto's self-service status gate).
  bool get isNew => status.toLowerCase() == 'new';

  /// "Street HouseNumber" joined; empty when neither is set. This is the
  /// report's own address, not the customer's profile address.
  String get address => [
    street?.trim() ?? '',
    houseNumber?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  factory CustomerFaultReport.fromJson(Map<String, dynamic> json) {
    return CustomerFaultReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt(),
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
      createdAt: _date(json['createdAt']),
      resolvedAt: _date(json['resolvedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
