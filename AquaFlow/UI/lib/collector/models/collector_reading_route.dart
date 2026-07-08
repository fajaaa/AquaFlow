/// A reading route assigned to the signed-in collector (`ReadingRouteResponse`).
/// The backend pins `GET /ReadingRoutes` to the caller's own
/// `CollectorProfile.Id` for the Collector role, so every route returned here
/// already belongs to them.
class CollectorReadingRoute {
  const CollectorReadingRoute({
    required this.id,
    required this.name,
    required this.scheduledDate,
    required this.status,
  });

  final int id;
  final String name;
  final DateTime? scheduledDate;
  final String status;

  factory CollectorReadingRoute.fromJson(Map<String, dynamic> json) {
    return CollectorReadingRoute(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      scheduledDate: _date(json['scheduledDate']),
      status: (json['status'] ?? '') as String,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
