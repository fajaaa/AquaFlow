/// The saved reading returned by `POST /MeterReadings/collector-entry`
/// (`MeterReadingCollectorEntryResponse`). Carries the server-computed
/// previous reading/consumption, plus the auto-generated Draft invoice's id,
/// number, and total amount, so the entry screen can show what was actually
/// recorded and billed.
class CollectorMeterReadingResult {
  const CollectorMeterReadingResult({
    required this.previousReadingValue,
    required this.readingValue,
    required this.consumptionM3,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceTotalAmount,
  });

  final double previousReadingValue;
  final double readingValue;
  final double consumptionM3;
  final int invoiceId;
  final String invoiceNumber;
  final double invoiceTotalAmount;

  factory CollectorMeterReadingResult.fromJson(Map<String, dynamic> json) {
    return CollectorMeterReadingResult(
      previousReadingValue:
          (json['previousReadingValue'] as num?)?.toDouble() ?? 0,
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      invoiceId: (json['invoiceId'] as num?)?.toInt() ?? 0,
      invoiceNumber: (json['invoiceNumber'] ?? '') as String,
      invoiceTotalAmount: (json['invoiceTotalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
