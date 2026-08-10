/// Metadata for one image attached to a notification (`NotificationImageResponse`).
/// Never carries the raw bytes - those are fetched separately (and lazily) via
/// `AdminNotificationService.fetchImageBytes`/`AuthenticatedImage`, since the
/// backend streams them from a Bearer-authenticated endpoint, not a public URL.
/// Mirrors `AdminFaultReportPhoto`.
class AdminNotificationImage {
  const AdminNotificationImage({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final int id;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final DateTime? createdAt;

  factory AdminNotificationImage.fromJson(Map<String, dynamic> json) {
    return AdminNotificationImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: (json['fileName'] ?? '') as String,
      contentType: (json['contentType'] ?? '') as String,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
