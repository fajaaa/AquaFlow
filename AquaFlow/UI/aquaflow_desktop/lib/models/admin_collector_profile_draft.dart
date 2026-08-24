class AdminCollectorProfileDraft {
  const AdminCollectorProfileDraft({required this.userId});

  final int userId;

  Map<String, Object?> toJson() {
    return {'userId': userId};
  }
}
