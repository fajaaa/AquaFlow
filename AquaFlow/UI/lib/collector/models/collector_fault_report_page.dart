import 'collector_fault_report.dart';

/// One page of fault reports (`PageResult<FaultReportResponse>`), used for the
/// server-side paginated list in `CollectorFaultReportsScreen`.
class CollectorFaultReportPage {
  const CollectorFaultReportPage({
    required this.items,
    required this.totalCount,
  });

  final List<CollectorFaultReport> items;
  final int totalCount;
}
