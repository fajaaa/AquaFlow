class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.settlementId,
    this.validUntil,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final String audience;
  final int? settlementId;
  final int createdById;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      audience: (json['audience'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt(),
      createdById: (json['createdById'] as num?)?.toInt() ?? 0,
      validUntil: _date(json['validUntil']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
