class AdminNotificationDraft {
  const AdminNotificationDraft({
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    required this.createdById,
    this.settlementId,
    this.validUntil,
  });

  final String title;
  final String body;
  final String type;
  final String audience;
  final int? settlementId;
  final int createdById;
  final DateTime? validUntil;

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'audience': audience,
      'settlementId': settlementId,
      'createdById': createdById,
      'validUntil': validUntil?.toUtc().toIso8601String(),
    };
  }
}
