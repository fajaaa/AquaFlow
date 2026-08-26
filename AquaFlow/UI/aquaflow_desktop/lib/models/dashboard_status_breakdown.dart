/// One slice of a status-breakdown chart, as returned by `GET /Dashboard/*-status`.
/// [totalAmount] is only populated where a money total makes sense (invoices).
class DashboardStatusBreakdown {
  const DashboardStatusBreakdown({
    required this.status,
    required this.count,
    this.totalAmount,
  });

  final String status;
  final int count;
  final double? totalAmount;

  factory DashboardStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return DashboardStatusBreakdown(
      status: (json['status'] ?? '') as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    );
  }
}
