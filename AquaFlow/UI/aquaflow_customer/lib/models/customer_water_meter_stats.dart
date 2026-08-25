import 'customer_invoice.dart';
import 'customer_water_meter.dart';

/// Consumption/billing summary for one water meter, computed entirely from
/// that meter's own invoices plus the meter itself - no separate API call.
/// `/MeterReadings` is not an option here: that endpoint is gated on
/// `MeterReadings.Manage` (see AGENTS.md), which the customer role does not
/// hold, so a customer can never read raw meter readings directly. Every
/// consumption figure a customer can see is derived from their own invoices
/// instead, which they are always allowed to read (`Invoices.Read`, pinned
/// to their `CustomerId`).
class CustomerWaterMeterStats {
  const CustomerWaterMeterStats._({
    required this.invoiceCount,
    required this.unpaidCount,
    required this.unpaidAmount,
    required this.totalConsumptionM3,
    required this.averageConsumptionM3,
    required this.lastBillingPeriodFrom,
    required this.lastBillingPeriodTo,
    required this.lastReading,
    required this._recentForChart,
  });

  final int invoiceCount;
  final int unpaidCount;
  final double unpaidAmount;
  final double totalConsumptionM3;
  final double averageConsumptionM3;
  final DateTime? lastBillingPeriodFrom;
  final DateTime? lastBillingPeriodTo;
  final double lastReading;

  final List<CustomerInvoice> _recentForChart;

  /// The last up to 6 non-cancelled invoices, oldest first, sized for the
  /// consumption chart.
  List<CustomerInvoice> get recentForChart => _recentForChart;

  factory CustomerWaterMeterStats.from({
    required CustomerWaterMeter meter,
    required List<CustomerInvoice> invoices,
  }) {
    final counted = invoices.where(_notCancelled).toList();
    final unpaid = invoices.where((invoice) => invoice.isPayable).toList();

    final totalConsumption = counted.fold<double>(
      0,
      (sum, invoice) => sum + invoice.consumptionM3,
    );

    CustomerInvoice? latest;
    for (final invoice in invoices) {
      if (latest == null ||
          invoice.billingPeriodFrom.isAfter(latest.billingPeriodFrom)) {
        latest = invoice;
      }
    }

    counted.sort((a, b) => a.billingPeriodFrom.compareTo(b.billingPeriodFrom));

    return CustomerWaterMeterStats._(
      invoiceCount: invoices.length,
      unpaidCount: unpaid.length,
      unpaidAmount: unpaid.fold<double>(
        0,
        (sum, invoice) => sum + invoice.remainingAmount,
      ),
      totalConsumptionM3: totalConsumption,
      averageConsumptionM3: counted.isEmpty
          ? 0
          : totalConsumption / counted.length,
      lastBillingPeriodFrom: latest?.billingPeriodFrom,
      lastBillingPeriodTo: latest?.billingPeriodTo,
      lastReading: meter.lastReading,
      recentForChart: counted.length <= 6
          ? counted
          : counted.sublist(counted.length - 6),
    );
  }

  static bool _notCancelled(CustomerInvoice invoice) =>
      invoice.status.toLowerCase() != 'cancelled';
}
