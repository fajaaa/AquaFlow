/// A water meter entry on a reading route assigned to the signed-in collector
/// (`ReadingRouteItemResponse`), read via `GET /ReadingRoutes/{id}/items`.
/// Purely informational here - no reading-entry action yet (that lands in a
/// later phase alongside the InProgress/Completed statuses).
class CollectorReadingRouteItem {
  const CollectorReadingRouteItem({
    required this.id,
    required this.waterMeterSerialNumber,
    required this.settlementName,
    required this.customerFirstName,
    required this.customerLastName,
    required this.status,
  });

  final int id;
  final String waterMeterSerialNumber;
  final String settlementName;
  final String customerFirstName;
  final String customerLastName;
  final String status;

  /// Customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory CollectorReadingRouteItem.fromJson(Map<String, dynamic> json) {
    return CollectorReadingRouteItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      waterMeterSerialNumber: (json['waterMeterSerialNumber'] ?? '') as String,
      settlementName: (json['settlementName'] ?? '') as String,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      status: (json['status'] ?? '') as String,
    );
  }
}
