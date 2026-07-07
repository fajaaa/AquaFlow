class AdminSettlement {
  const AdminSettlement({
    required this.id,
    required this.name,
    required this.municipalityId,
    required this.municipalityName,
    required this.postalCode,
  });

  final int id;
  final String name;
  final int municipalityId;
  final String municipalityName;
  final String postalCode;

  factory AdminSettlement.fromJson(Map<String, dynamic> json) {
    return AdminSettlement(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      municipalityId: (json['municipalityId'] as num?)?.toInt() ?? 0,
      municipalityName: (json['municipalityName'] ?? '') as String,
      postalCode: (json['postalCode'] ?? '') as String,
    );
  }
}
