import 'customer_support_ticket.dart';

/// One page of the signed-in customer's support tickets
/// (`PageResult<SupportTicketResponse>`), used for the server-side paginated /
/// infinite-scroll list in `CustomerSupportTicketsScreen`.
class CustomerSupportTicketPage {
  const CustomerSupportTicketPage({
    required this.items,
    required this.totalCount,
  });

  final List<CustomerSupportTicket> items;
  final int totalCount;
}
