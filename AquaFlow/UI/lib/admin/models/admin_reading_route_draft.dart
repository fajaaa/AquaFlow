class AdminReadingRouteDraft {
  const AdminReadingRouteDraft({required this.name, required this.scheduledDate});

  final String name;
  final DateTime scheduledDate;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'scheduledDate': scheduledDate.toIso8601String(),
    };
  }
}
