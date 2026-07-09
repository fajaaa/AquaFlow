/// Read-only billing-cycle lookup entry for the invoices screen's cycle
/// filter dropdown (`BillingCycleResponse`, via `GET /BillingCycles`).
class AdminInvoiceBillingCycleOption {
  const AdminInvoiceBillingCycleOption({
    required this.id,
    required this.name,
    required this.periodFrom,
    required this.periodTo,
  });

  final int id;
  final String name;
  final DateTime periodFrom;
  final DateTime periodTo;

  factory AdminInvoiceBillingCycleOption.fromJson(Map<String, dynamic> json) {
    return AdminInvoiceBillingCycleOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      periodFrom: DateTime.tryParse((json['periodFrom'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      periodTo: DateTime.tryParse((json['periodTo'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
