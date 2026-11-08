/// Forecast + personalised recommendations for one of the caller's water
/// meters (`GET /ConsumptionInsights/water-meters/{id}`).
class ConsumptionInsight {
  const ConsumptionInsight({
    required this.waterMeterId,
    required this.serialNumber,
    required this.hasEnoughData,
    required this.readingsCount,
    required this.recentAverageM3,
    required this.predictedNextM3,
    required this.predictedLowerM3,
    required this.predictedUpperM3,
    required this.estimatedNextAmount,
    required this.currency,
    required this.settlementAverageM3,
    required this.history,
    required this.openAlert,
    required this.recommendations,
  });

  final int waterMeterId;
  final String serialNumber;
  final bool hasEnoughData;
  final int readingsCount;
  final double recentAverageM3;
  final double predictedNextM3;
  final double predictedLowerM3;
  final double predictedUpperM3;
  final double? estimatedNextAmount;
  final String currency;
  final double? settlementAverageM3;
  final List<ConsumptionHistoryPoint> history;
  final ConsumptionInsightAlert? openAlert;
  final List<ConsumptionRecommendation> recommendations;

  factory ConsumptionInsight.fromJson(Map<String, dynamic> json) {
    final alertJson = json['openAlert'];
    return ConsumptionInsight(
      waterMeterId: (json['waterMeterId'] as num?)?.toInt() ?? 0,
      serialNumber: (json['serialNumber'] ?? '') as String,
      hasEnoughData: json['hasEnoughData'] == true,
      readingsCount: (json['readingsCount'] as num?)?.toInt() ?? 0,
      recentAverageM3: (json['recentAverageM3'] as num?)?.toDouble() ?? 0,
      predictedNextM3: (json['predictedNextM3'] as num?)?.toDouble() ?? 0,
      predictedLowerM3: (json['predictedLowerM3'] as num?)?.toDouble() ?? 0,
      predictedUpperM3: (json['predictedUpperM3'] as num?)?.toDouble() ?? 0,
      estimatedNextAmount: (json['estimatedNextAmount'] as num?)?.toDouble(),
      currency: (json['currency'] ?? 'KM') as String,
      settlementAverageM3: (json['settlementAverageM3'] as num?)?.toDouble(),
      history: _list(json['history'], ConsumptionHistoryPoint.fromJson),
      openAlert: alertJson is Map<String, dynamic>
          ? ConsumptionInsightAlert.fromJson(alertJson)
          : null,
      recommendations: _list(
        json['recommendations'],
        ConsumptionRecommendation.fromJson,
      ),
    );
  }

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().map(parse).toList();
  }
}

class ConsumptionHistoryPoint {
  const ConsumptionHistoryPoint({
    required this.readingDate,
    required this.consumptionM3,
  });

  final DateTime? readingDate;
  final double consumptionM3;

  factory ConsumptionHistoryPoint.fromJson(Map<String, dynamic> json) {
    final date = json['readingDate'];
    return ConsumptionHistoryPoint(
      readingDate: date is String ? DateTime.tryParse(date)?.toLocal() : null,
      consumptionM3: (json['consumptionM3'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// The open consumption alert of the meter, with the model's 95 % expected
/// interval when the alert was raised by the forecast model.
class ConsumptionInsightAlert {
  const ConsumptionInsightAlert({
    required this.id,
    required this.createdAt,
    required this.measuredValue,
    required this.expectedValue,
    required this.expectedLowerBound,
    required this.expectedUpperBound,
    required this.thresholdValue,
  });

  final int id;
  final DateTime? createdAt;
  final double measuredValue;
  final double? expectedValue;
  final double? expectedLowerBound;
  final double? expectedUpperBound;
  final double thresholdValue;

  bool get hasExpectedInterval =>
      expectedValue != null &&
      expectedLowerBound != null &&
      expectedUpperBound != null;

  factory ConsumptionInsightAlert.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return ConsumptionInsightAlert(
      id: (json['id'] as num?)?.toInt() ?? 0,
      createdAt: created is String
          ? DateTime.tryParse(created)?.toLocal()
          : null,
      measuredValue: (json['measuredValue'] as num?)?.toDouble() ?? 0,
      expectedValue: (json['expectedValue'] as num?)?.toDouble(),
      expectedLowerBound: (json['expectedLowerBound'] as num?)?.toDouble(),
      expectedUpperBound: (json['expectedUpperBound'] as num?)?.toDouble(),
      thresholdValue: (json['thresholdValue'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One recommendation: a stable [code] the app maps to localized text, a
/// [severity] (`warning` | `info` | `positive`) and the numbers it was derived
/// from in [parameters] (the "why").
class ConsumptionRecommendation {
  const ConsumptionRecommendation({
    required this.code,
    required this.severity,
    required this.parameters,
  });

  final String code;
  final String severity;
  final Map<String, double> parameters;

  double? param(String name) => parameters[name];

  factory ConsumptionRecommendation.fromJson(Map<String, dynamic> json) {
    final raw = json['parameters'];
    final params = <String, double>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String && value is num) params[key] = value.toDouble();
      });
    }
    return ConsumptionRecommendation(
      code: (json['code'] ?? '') as String,
      severity: (json['severity'] ?? 'info') as String,
      parameters: params,
    );
  }
}
