/// Metadata for one image attached to a notification (`NotificationImageResponse`),
/// for the recipient-facing side (customer/collector, via `NotificationService`).
/// Never carries the raw bytes - those are fetched separately (and lazily) via
/// `NotificationService.fetchImageBytes`/`AuthenticatedImage`. Shared (not per-role)
/// because the recipient notification UI is already unified across customer/collector,
/// unlike fault reports. Mirrors `AdminNotificationImage`.
class NotificationImage {
  const NotificationImage({
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

  factory NotificationImage.fromJson(Map<String, dynamic> json) {
    return NotificationImage(
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
