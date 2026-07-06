class AdminSettlementOption {
  const AdminSettlementOption({
    required this.id,
    required this.name,
    required this.city,
    required this.postalCode,
  });

  final int id;
  final String name;
  final String city;
  final String postalCode;

  String get label {
    final parts = [name.trim(), city.trim()].where((part) => part.isNotEmpty);
    final text = parts.join(', ');
    return text.isEmpty ? 'Područje #$id' : text;
  }

  factory AdminSettlementOption.fromJson(Map<String, dynamic> json) {
    return AdminSettlementOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      postalCode: (json['postalCode'] ?? '') as String,
    );
  }
}
