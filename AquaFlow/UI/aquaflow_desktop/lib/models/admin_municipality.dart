class AdminMunicipality {
  const AdminMunicipality({
    required this.id,
    required this.name,
    required this.code,
    required this.cityId,
    required this.cityName,
  });

  final int id;
  final String name;
  final String code;
  final int cityId;
  final String cityName;

  factory AdminMunicipality.fromJson(Map<String, dynamic> json) {
    return AdminMunicipality(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
      cityName: (json['cityName'] ?? '') as String,
    );
  }
}
