class AdminRecommendationException implements Exception {
  const AdminRecommendationException(this.message);

  final String message;

  @override
  String toString() => message;
}
