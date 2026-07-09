/// A payment as returned by `/Payments` (`PaymentResponse`). Payments are
/// never created/edited/deleted from this screen - they arise exclusively
/// through the "Evidentiraj uplatu" action on the Računi screen
/// (`AdminInvoiceService.recordPayment` -> `POST /Invoices/{id}/payments`).
class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.invoiceId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
    required this.transactionReference,
    required this.createdAt,
  });

  final int id;
  final int invoiceId;
  final int customerId;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime? paidAt;
  final String? transactionReference;
  final DateTime? createdAt;

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceId: (json['invoiceId'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      paidAt: _date(json['paidAt']),
      transactionReference: json['transactionReference'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
