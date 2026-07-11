import 'customer_fault_report.dart';

/// One page of the signed-in customer's fault reports (`PageResult<FaultReportResponse>`),
/// used for the server-side paginated / infinite-scroll list in
/// `CustomerFaultReportsScreen`.
class CustomerFaultReportPage {
  const CustomerFaultReportPage({required this.items, required this.totalCount});

  final List<CustomerFaultReport> items;
  final int totalCount;
}
