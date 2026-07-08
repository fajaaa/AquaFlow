class AdminTariffDraft {
  const AdminTariffDraft({
    required this.name,
    required this.description,
    required this.pricePerM3,
    required this.isActive,
  });

  final String name;
  final String description;
  final double pricePerM3;
  final bool isActive;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'pricePerM3': pricePerM3,
      'isActive': isActive,
    };
  }
}
