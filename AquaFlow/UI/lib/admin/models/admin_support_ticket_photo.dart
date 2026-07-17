/// Metadata for one photo attached to a support ticket message
/// (`SupportTicketPhotoResponse`). Never carries the raw bytes - those are
/// fetched separately (and lazily) via
/// `AdminSupportTicketService.fetchPhotoBytes`/`AuthenticatedImage`, since the
/// backend streams them from a Bearer-authenticated endpoint, not a public URL.
/// Mirrors `CustomerSupportTicketPhoto`.
class AdminSupportTicketPhoto {
  const AdminSupportTicketPhoto({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  final int id;
  final String fileName;
  final String contentType;
  final int sizeBytes;

  factory AdminSupportTicketPhoto.fromJson(Map<String, dynamic> json) {
    return AdminSupportTicketPhoto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: (json['fileName'] ?? '') as String,
      contentType: (json['contentType'] ?? '') as String,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
