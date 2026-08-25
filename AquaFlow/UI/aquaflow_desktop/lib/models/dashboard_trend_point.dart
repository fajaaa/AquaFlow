/// One point of a monthly trend chart, as returned by `GET /Dashboard/*-trend`.
/// [periodStart] is always the first day of a month (UTC).
class DashboardTrendPoint {
  const DashboardTrendPoint({required this.periodStart, required this.value});

  final DateTime periodStart;
  final double value;

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      periodStart: DateTime.parse(json['periodStart'] as String),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}
