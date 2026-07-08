/// The saved reading returned by `POST /MeterReadings/collector-entry`
/// (`MeterReadingResponse`). Carries the server-computed previous reading and
/// consumption so the entry screen can show what was actually recorded.
class CollectorMeterReadingResult {
  const CollectorMeterReadingResult({
    required this.previousReadingValue,
    required this.readingValue,
    required this.consumptionM3,
  });

  final double previousReadingValue;
  final double readingValue;
  final double consumptionM3;

  factory CollectorMeterReadingResult.fromJson(Map<String, dynamic> json) {
    return CollectorMeterReadingResult(
      previousReadingValue:
          (json['previousReadingValue'] as num?)?.toDouble() ?? 0,
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
    );
  }
}
