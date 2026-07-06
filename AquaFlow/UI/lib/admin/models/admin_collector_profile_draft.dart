class AdminCollectorProfileDraft {
  const AdminCollectorProfileDraft({
    required this.userId,
    required this.assignedAreaId,
  });

  final int userId;
  final int? assignedAreaId;

  Map<String, Object?> toJson() {
    return {'userId': userId, 'assignedAreaId': assignedAreaId};
  }
}
