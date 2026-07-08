class AdminTariff {
  const AdminTariff({
    required this.id,
    required this.name,
    required this.customerType,
    required this.pricePerM3,
    required this.fixedFee,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String customerType;
  final double pricePerM3;
  final double fixedFee;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final DateTime? createdAt;

  bool get isExpired =>
      effectiveTo != null && effectiveTo!.isBefore(DateTime.now());

  factory AdminTariff.fromJson(Map<String, dynamic> json) {
    return AdminTariff(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      customerType: (json['customerType'] ?? '') as String,
      pricePerM3: (json['pricePerM3'] as num?)?.toDouble() ?? 0,
      fixedFee: (json['fixedFee'] as num?)?.toDouble() ?? 0,
      effectiveFrom: _date(json['effectiveFrom']),
      effectiveTo: _date(json['effectiveTo']),
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
