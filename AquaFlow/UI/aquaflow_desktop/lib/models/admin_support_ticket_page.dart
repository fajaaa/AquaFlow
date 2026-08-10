import 'admin_support_ticket.dart';

/// One page of `SupportTicketResponse` rows (`PageResult<SupportTicketResponse>`),
/// used for the server-side paginated table on `AdminSupportTicketsScreen`.
class AdminSupportTicketPage {
  const AdminSupportTicketPage({required this.items, required this.totalCount});

  final List<AdminSupportTicket> items;
  final int totalCount;
}
