/// The currently Open billing period (`BillingCycleResponse`), shown on the
/// reading-entry screen so the collector knows which period a reading will
/// be recorded against. Read-only - cycles are opened/closed server-side,
/// there is no collector/admin UI for that yet.
class CollectorBillingCycle {
  const CollectorBillingCycle({
    required this.id,
    required this.name,
    required this.periodFrom,
    required this.periodTo,
    required this.status,
  });

  final int id;
  final String name;
  final DateTime periodFrom;
  final DateTime periodTo;
  final String status;

  factory CollectorBillingCycle.fromJson(Map<String, dynamic> json) {
    return CollectorBillingCycle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      periodFrom: DateTime.parse(json['periodFrom'] as String),
      periodTo: DateTime.parse(json['periodTo'] as String),
      status: (json['status'] ?? '') as String,
    );
  }
}
