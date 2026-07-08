class AdminTariffDraft {
  const AdminTariffDraft({
    required this.name,
    required this.customerType,
    required this.pricePerM3,
    required this.fixedFee,
    required this.effectiveFrom,
    required this.isActive,
    this.effectiveTo,
  });

  final String name;
  final String customerType;
  final double pricePerM3;
  final double fixedFee;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'customerType': customerType,
      'pricePerM3': pricePerM3,
      'fixedFee': fixedFee,
      'effectiveFrom': effectiveFrom.toUtc().toIso8601String(),
      'effectiveTo': effectiveTo?.toUtc().toIso8601String(),
      'isActive': isActive,
    };
  }
}
