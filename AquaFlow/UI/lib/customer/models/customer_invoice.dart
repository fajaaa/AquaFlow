/// An invoice as returned by `/Invoices` (`InvoiceResponse`), scoped to the
/// signed-in customer (the backend pins `CustomerId` to the caller - see the
/// Invoice ownership-pinning rule in AGENTS.md). Carries the source meter's
/// serial number (`WaterMeterSerialNumber`, flattened from the linked
/// `WaterMeter`) directly, same pattern as `AdminInvoice`.
class CustomerInvoice {
  const CustomerInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.billingPeriodFrom,
    required this.billingPeriodTo,
    required this.previousReading,
    required this.currentReading,
    required this.consumptionM3,
    required this.subtotal,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.waterMeterSerialNumber,
  });

  final int id;
  final String invoiceNumber;
  final DateTime billingPeriodFrom;
  final DateTime billingPeriodTo;
  final double previousReading;
  final double currentReading;
  final double consumptionM3;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final String status;
  final String waterMeterSerialNumber;

  /// Whether this invoice still has an outstanding balance a customer could
  /// act on (Issued/PartiallyPaid/Overdue) - Draft isn't final yet and
  /// Paid/Cancelled have nothing left to pay.
  bool get isPayable => const {
    'issued',
    'partiallypaid',
    'overdue',
  }.contains(status.toLowerCase());

  factory CustomerInvoice.fromJson(Map<String, dynamic> json) {
    return CustomerInvoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: (json['invoiceNumber'] ?? '') as String,
      billingPeriodFrom: _dateRequired(json['billingPeriodFrom']),
      billingPeriodTo: _dateRequired(json['billingPeriodTo']),
      previousReading: (json['previousReading'] as num?)?.toDouble() ?? 0,
      currentReading: (json['currentReading'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? '') as String,
      waterMeterSerialNumber: (json['waterMeterSerialNumber'] ?? '') as String,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static DateTime _dateRequired(Object? value) {
    return _date(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
