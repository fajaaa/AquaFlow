/// Last reading of a meter (`MeterReadingResponse`), retrieved to suggest
/// a tariff and check the minimum spacing before the next reading (15 days).
class CollectorMeterReading {
  const CollectorMeterReading({
    required this.id,
    required this.readingDate,
    this.tariffId,
    required this.readingValue,
  });

  final int id;
  final DateTime readingDate;
  final int? tariffId;
  final double readingValue;

  factory CollectorMeterReading.fromJson(Map<String, dynamic> json) {
    return CollectorMeterReading(
      id: (json['id'] as num?)?.toInt() ?? 0,
      readingDate: DateTime.parse(json['readingDate'] as String),
      tariffId: (json['tariffId'] as num?)?.toInt(),
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
    );
  }
}
