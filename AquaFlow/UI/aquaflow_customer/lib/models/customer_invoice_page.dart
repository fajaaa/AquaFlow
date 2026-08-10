import 'customer_invoice.dart';

/// One page of the signed-in customer's invoices (`PageResult<InvoiceResponse>`),
/// used for the server-side paginated / infinite-scroll list in
/// `CustomerInvoicesScreen`.
class CustomerInvoicePage {
  const CustomerInvoicePage({required this.items, required this.totalCount});

  final List<CustomerInvoice> items;
  final int totalCount;
}
