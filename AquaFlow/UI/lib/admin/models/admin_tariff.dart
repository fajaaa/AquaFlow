class AdminTariff {
  const AdminTariff({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerM3,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String description;
  final double pricePerM3;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminTariff.fromJson(Map<String, dynamic> json) {
    return AdminTariff(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      pricePerM3: (json['pricePerM3'] as num?)?.toDouble() ?? 0,
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
