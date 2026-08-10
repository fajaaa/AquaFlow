import 'admin_support_ticket_message.dart';

/// A support ticket as returned by `/SupportTickets` (`SupportTicketResponse`).
/// `Status` mirrors the backend `SupportTicketStatus` column (Open/Closed).
/// Carries the opening customer's name (`CustomerName`, flattened server-side
/// from the linked `CustomerProfile`) so the admin list can show who opened
/// the ticket without a separate lookup.
///
/// The [messages] thread is fully populated on `GET /SupportTickets/{id}`
/// (`AdminSupportTicketService.fetchById`) and left empty on the list endpoint
/// (`fetch`), where only the header fields are shown.
class AdminSupportTicket {
  const AdminSupportTicket({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.subject,
    required this.status,
    required this.closedAt,
    required this.lastMessageAt,
    required this.lastMessageFromStaff,
    required this.messageCount,
    required this.createdAt,
    required this.messages,
  });

  final int id;
  final int customerId;
  final String? customerName;
  final String subject;
  final String status;
  final DateTime? closedAt;
  final DateTime? lastMessageAt;
  // True when the newest message in the thread is a staff reply. Combined
  // with isOpen this drives the "awaiting reply" highlight on the admin list.
  final bool lastMessageFromStaff;
  final int messageCount;
  final DateTime? createdAt;
  final List<AdminSupportTicketMessage> messages;

  bool get isClosed => status.toLowerCase() == 'closed';

  /// An open ticket whose newest message is not a staff reply - i.e. the
  /// customer is waiting to hear back.
  bool get awaitingReply => !isClosed && !lastMessageFromStaff;

  factory AdminSupportTicket.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'];
    return AdminSupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerName: json['customerName'] as String?,
      subject: (json['subject'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      closedAt: _date(json['closedAt']),
      lastMessageAt: _date(json['lastMessageAt']),
      lastMessageFromStaff: (json['lastMessageFromStaff'] as bool?) ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
      messages: messagesJson is List
          ? messagesJson
              .whereType<Map<String, dynamic>>()
              .map(AdminSupportTicketMessage.fromJson)
              .toList()
          : const [],
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
