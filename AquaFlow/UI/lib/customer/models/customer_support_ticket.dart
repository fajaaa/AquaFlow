import 'customer_support_ticket_message.dart';

/// A customer's support ticket (`SupportTicketResponse`). `Status` mirrors the
/// backend `SupportTicketStatus` column (Open/Closed).
///
/// The [messages] thread is fully populated on `GET /SupportTickets/{id}`
/// (`CustomerSupportTicketService.fetchById`) and left empty on the list
/// endpoint (`fetchMine`), where only the header fields (subject, status,
/// last-message time, count) are shown.
class CustomerSupportTicket {
  const CustomerSupportTicket({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.subject,
    required this.status,
    required this.closedAt,
    required this.lastMessageAt,
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
  final int messageCount;
  final DateTime? createdAt;
  final List<CustomerSupportTicketMessage> messages;

  /// A closed ticket can no longer receive replies - the detail screen hides
  /// the composer and shows "Tiket je zatvoren" instead (mirrors
  /// `SupportTicketService.AddMessageAsync`'s Open-only rule).
  bool get isClosed => status.toLowerCase() == 'closed';

  factory CustomerSupportTicket.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'];
    return CustomerSupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerName: json['customerName'] as String?,
      subject: (json['subject'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      closedAt: _date(json['closedAt']),
      lastMessageAt: _date(json['lastMessageAt']),
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['createdAt']),
      messages: messagesJson is List
          ? messagesJson
              .whereType<Map<String, dynamic>>()
              .map(CustomerSupportTicketMessage.fromJson)
              .toList()
          : const [],
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
