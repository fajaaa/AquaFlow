import 'admin_support_ticket_photo.dart';

/// One message in a support ticket thread (`SupportTicketMessageResponse`).
///
/// [isFromStaff] drives the chat layout in `AdminSupportTicketDetailScreen`:
/// the signed-in admin's own messages render on the right, the customer's on
/// the left. The backend derives it from the sender's permission, never a
/// client-supplied flag. Mirrors `CustomerSupportTicketMessage`.
class AdminSupportTicketMessage {
  const AdminSupportTicketMessage({
    required this.id,
    required this.supportTicketId,
    required this.senderId,
    required this.senderName,
    required this.isFromStaff,
    required this.body,
    required this.createdAt,
    required this.photos,
  });

  final int id;
  final int supportTicketId;
  final int senderId;
  final String? senderName;
  final bool isFromStaff;
  final String body;
  final DateTime? createdAt;
  final List<AdminSupportTicketPhoto> photos;

  factory AdminSupportTicketMessage.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'];
    return AdminSupportTicketMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      supportTicketId: (json['supportTicketId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      senderName: json['senderName'] as String?,
      isFromStaff: (json['isFromStaff'] as bool?) ?? false,
      body: (json['body'] ?? '') as String,
      createdAt: _date(json['createdAt']),
      photos: photosJson is List
          ? photosJson
              .whereType<Map<String, dynamic>>()
              .map(AdminSupportTicketPhoto.fromJson)
              .toList()
          : const [],
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
