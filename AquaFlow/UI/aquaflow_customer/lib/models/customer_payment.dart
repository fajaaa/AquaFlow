/// A completed payment against one of the signed-in customer's invoices, as
/// returned by `/Payments` (`PaymentResponse`). Only the fields the invoice
/// detail screen needs are kept - amount, when it was paid, and its status.
class CustomerPayment {
  const CustomerPayment({
    required this.amount,
    required this.paidAt,
    required this.status,
  });

  final double amount;
  final DateTime? paidAt;
  final String status;

  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidAt: _date(json['paidAt']),
      status: (json['status'] ?? '') as String,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
