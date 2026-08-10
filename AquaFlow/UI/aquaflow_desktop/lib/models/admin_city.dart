class AdminCity {
  const AdminCity({required this.id, required this.name, required this.code});

  final int id;
  final String name;
  final String code;

  factory AdminCity.fromJson(Map<String, dynamic> json) {
    return AdminCity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
    );
  }
}
