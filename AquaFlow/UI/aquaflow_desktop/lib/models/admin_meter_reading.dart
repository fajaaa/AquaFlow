class AdminMeterReading {
  const AdminMeterReading({
    required this.id,
    required this.waterMeterId,
    required this.collectorId,
    required this.readingValue,
    required this.previousReadingValue,
    required this.consumptionM3,
    required this.readingDate,
    required this.syncStatus,
    required this.note,
  });

  final int id;
  final int waterMeterId;
  final int collectorId;
  final double readingValue;
  final double previousReadingValue;
  final double consumptionM3;
  final DateTime? readingDate;
  final String syncStatus;
  final String? note;

  factory AdminMeterReading.fromJson(Map<String, dynamic> json) {
    return AdminMeterReading(
      id: (json['id'] as num?)?.toInt() ?? 0,
      waterMeterId: (json['waterMeterId'] as num?)?.toInt() ?? 0,
      collectorId: (json['collectorId'] as num?)?.toInt() ?? 0,
      readingValue: (json['readingValue'] as num?)?.toDouble() ?? 0,
      previousReadingValue:
          (json['previousReadingValue'] as num?)?.toDouble() ?? 0,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
      readingDate: _date(json['readingDate']),
      syncStatus: (json['syncStatus'] ?? '') as String,
      note: json['note'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
