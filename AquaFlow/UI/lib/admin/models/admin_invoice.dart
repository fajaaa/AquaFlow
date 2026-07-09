/// An invoice as returned by `/Invoices` (`InvoiceResponse`). Carries the
/// owning customer's name (`CustomerFirstName`/`CustomerLastName`, flattened
/// from the linked `CustomerProfile`) and the source meter's serial number
/// (`WaterMeterSerialNumber`, flattened from the linked `WaterMeter`)
/// directly, so the admin table can show who/what an invoice is for without a
/// per-row lookup - same pattern as `AdminWaterMeterRequest`.
class AdminInvoice {
  const AdminInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.waterMeterId,
    required this.waterMeterSerialNumber,
    required this.billingCycleId,
    required this.billingPeriodFrom,
    required this.billingPeriodTo,
    required this.previousReading,
    required this.currentReading,
    required this.consumptionM3,
    required this.subtotal,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.createdById,
    required this.createdAt,
  });

  final int id;
  final String invoiceNumber;
  final int customerId;
  final String customerFirstName;
  final String customerLastName;
  final int waterMeterId;
  final String waterMeterSerialNumber;
  final int? billingCycleId;
  final DateTime billingPeriodFrom;
  final DateTime billingPeriodTo;
  final double previousReading;
  final double currentReading;
  final double consumptionM3;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final String status;
  final int createdById;
  final DateTime? createdAt;

  /// Owning customer's first and last name joined; empty when unknown.
  String get customerFullName => '$customerFirstName $customerLastName'.trim();

  factory AdminInvoice.fromJson(Map<String, dynamic> json) {
    return AdminInvoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: (json['invoiceNumber'] ?? '') as String,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerFirstName: (json['customerFirstName'] ?? '') as String,
      customerLastName: (json['customerLastName'] ?? '') as String,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt() ?? 0,
      waterMeterSerialNumber: (json['waterMeterSerialNumber'] ?? '') as String,
      billingCycleId: (json['billingCycleId'] as num?)?.toInt(),
      billingPeriodFrom: _dateRequired(json['billingPeriodFrom']),
      billingPeriodTo: _dateRequired(json['billingPeriodTo']),
      previousReading: (json['previousReading'] as num?)?.toDouble() ?? 0,
      currentReading: (json['currentReading'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? '') as String,
      createdById: (json['createdById'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
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
