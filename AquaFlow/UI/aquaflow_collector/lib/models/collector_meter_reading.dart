/// Last reading of a meter (`MeterReadingResponse`), retrieved to suggest
/// a tariff and check the minimum spacing before the next reading (15 days).
class CollectorMeterReading {
  const CollectorMeterReading({
    required this.id,
    required this.readingDate,
    this.tariffId,
    required this.readingValue,
    this.previousReadingValue = 0,
    this.consumptionM3 = 0,
    this.note,
    this.voidedAt,
    this.invoiceId,
  });

  final int id;
  final DateTime readingDate;
  final int? tariffId;
  final double readingValue;
  final double previousReadingValue;
  final double consumptionM3;
  final String? note;
  final DateTime? voidedAt;
  final int? invoiceId;

  factory CollectorMeterReading.fromJson(Map<String, dynamic> json) {
    return CollectorMeterReading(
      id: (json['id'] as num?)?.toInt() ?? 0,
      readingDate: DateTime.parse(json['readingDate'] as String),
      tariffId: (json['tariffId'] as num?)?.toInt(),
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
      previousReadingValue:
          (json['previousReadingValue'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
      voidedAt: json['voidedAt'] == null
          ? null
          : DateTime.parse(json['voidedAt'] as String),
      invoiceId: (json['invoiceId'] as num?)?.toInt(),
    );
  }
}
