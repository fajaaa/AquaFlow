import 'package:aquaflow_desktop/models/dashboard_status_breakdown.dart';
import 'package:aquaflow_desktop/models/dashboard_trend_point.dart';

/// Bundles the results of all 6 `/Dashboard/*` endpoints for one filter
/// selection, so [AdminDashboardService.fetchStats] can hand the dashboard
/// screen a single object instead of 6 separate futures.
class DashboardStats {
  const DashboardStats({
    required this.revenueTrend,
    required this.invoiceStatus,
    required this.consumptionTrend,
    required this.faultReportStatus,
    required this.userGrowthTrend,
    required this.waterMeterRequestStatus,
  });

  final List<DashboardTrendPoint> revenueTrend;
  final List<DashboardStatusBreakdown> invoiceStatus;
  final List<DashboardTrendPoint> consumptionTrend;
  final List<DashboardStatusBreakdown> faultReportStatus;
  final List<DashboardTrendPoint> userGrowthTrend;
  final List<DashboardStatusBreakdown> waterMeterRequestStatus;
}
