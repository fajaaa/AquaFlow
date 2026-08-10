/// The saved reading returned by `POST /MeterReadings/collector-entry`
/// (`MeterReadingCollectorEntryResponse`). Carries the server-computed
/// previous reading/consumption, plus the auto-generated Issued invoice's id,
/// number, and total amount, so the entry screen can show what was actually
/// recorded and billed. The invoice fields are null when the reading's
/// consumption was zero - the server does not create an invoice in that case
/// (see MeterReadingService.CreateForCollectorAsync), so [hasInvoice] is how
/// the screen tells "no invoice was created" apart from "invoice id is 0".
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
  final int? invoiceId;
  final String? invoiceNumber;
  final double? invoiceTotalAmount;

  bool get hasInvoice => invoiceId != null;

  factory CollectorMeterReadingResult.fromJson(Map<String, dynamic> json) {
    return CollectorMeterReadingResult(
      previousReadingValue:
          (json['previousReadingValue'] as num?)?.toDouble() ?? 0,
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      invoiceId: (json['invoiceId'] as num?)?.toInt(),
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceTotalAmount: (json['invoiceTotalAmount'] as num?)?.toDouble(),
    );
  }
}
