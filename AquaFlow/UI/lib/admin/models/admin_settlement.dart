class AdminSettlement {
  const AdminSettlement({
    required this.id,
    required this.name,
    required this.city,
    required this.postalCode,
  });

  final int id;
  final String name;
  final String city;
  final String postalCode;

  factory AdminSettlement.fromJson(Map<String, dynamic> json) {
    return AdminSettlement(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      postalCode: (json['postalCode'] ?? '') as String,
    );
  }
}
