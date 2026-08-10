class AdminNotificationDraft {
  const AdminNotificationDraft({
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    required this.createdById,
  });

  final String title;
  final String body;
  final String type;
  final String audience;
  final int createdById;

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'audience': audience,
      'createdById': createdById,
    };
  }
}
