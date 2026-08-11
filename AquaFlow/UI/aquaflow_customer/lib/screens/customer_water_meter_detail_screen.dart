import 'package:flutter/material.dart';

import 'package:aquaflow_customer/models/customer_invoice.dart';
import 'package:aquaflow_customer/models/customer_water_meter.dart';
import 'package:aquaflow_customer/models/customer_water_meter_stats.dart';
import 'package:aquaflow_customer/screens/customer_invoice_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_customer/services/customer_invoice_service.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';
import 'package:aquaflow_customer/shared/utils/money_format.dart';
import 'package:aquaflow_customer/shared/widgets/async_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/list_skeleton.dart';
import 'package:aquaflow_customer/widgets/invoice_summary_card.dart';
import 'package:aquaflow_customer/widgets/water_meter_status_pill.dart';

/// Detail view of a single water meter belonging to the signed-in customer,
/// pushed as its own Scaffold+AppBar route - same push pattern as
/// `CustomerInvoiceDetailScreen`. Loads that meter's own invoices
/// (`CustomerInvoiceService.fetchAllForMeter`, backend pins `CustomerId` to
/// the caller) and derives every consumption/billing figure from them via
/// `CustomerWaterMeterStats.from` - there is no separate stats endpoint.
class CustomerWaterMeterDetailScreen extends StatefulWidget {
  const CustomerWaterMeterDetailScreen({super.key, required this.meter});

  final CustomerWaterMeter meter;

  @override
  State<CustomerWaterMeterDetailScreen> createState() =>
      _CustomerWaterMeterDetailScreenState();
}

class _CustomerWaterMeterDetailScreenState
    extends State<CustomerWaterMeterDetailScreen> {
  final CustomerInvoiceService _service = CustomerInvoiceService();

  bool _loading = true;
  String? _error;
  List<CustomerInvoice> _invoices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final invoices = await _service.fetchAllForMeter(widget.meter.id);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } on CustomerInvoiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // CustomerInvoiceDetailScreen never returns a result through pop (payment
  // completion isn't signalled that way), so an unconditional reload here is
  // the only way this screen's stats/"Neplaćeno"/card statuses pick up a
  // payment made on the detail screen.
  Future<void> _openInvoice(CustomerInvoice invoice) async {
    await context.pushScreen(CustomerInvoiceDetailScreen(invoice: invoice));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final meter = widget.meter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final meta = WaterMeterStatusMeta.of(meter.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(title: Text(meter.serialNumber)),
      body: SafeArea(
        child: AsyncStateView(
          loading: _loading,
          error: _error,
          onRetry: _load,
          loadingBuilder: (context) => ListSkeleton(
            itemCount: 4,
            itemBuilder: (context, index) => const _SkeletonCard(),
          ),
          builder: (context) {
            final stats = CustomerWaterMeterStats.from(
              meter: meter,
              invoices: _invoices,
            );

            return RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status banner - full-width strip across the top, same
                    // treatment as the status banner on
                    // CustomerInvoiceDetailScreen.
                    Container(
                      width: double.infinity,
                      color: accent.withValues(alpha: 0.10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(meta.icon, color: onAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meter.serialNumber,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meta.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MeterInfoCard(meter: meter, accent: accent),
                          const SizedBox(height: 16),
                          _StatsCard(stats: stats, accent: accent),
                          const SizedBox(height: 16),
                          _ConsumptionChartCard(stats: stats, accent: accent),
                          const SizedBox(height: 16),
                          _InvoicesSection(
                            invoices: _invoices,
                            accent: accent,
                            onOpenInvoice: _openInvoice,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Mirrors `_readableAccent` in customer_invoice_detail_screen.dart: any
  /// accent dark enough to blend into the dark theme's background is lifted
  /// toward white there. Light theme and the brighter accents are returned
  /// unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }
}

class _MeterInfoCard extends StatelessWidget {
  const _MeterInfoCard({required this.meter, required this.accent});

  final CustomerWaterMeter meter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Podaci o vodomjeru',
            icon: Icons.info_outline,
            color: accent,
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Naselje',
            value: meter.settlementName.trim().isEmpty
                ? '-'
                : meter.settlementName,
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Adresa',
            value: meter.address.isEmpty ? '-' : meter.address,
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Datum ugradnje',
            value: meter.installedAt != null
                ? _formatDate(meter.installedAt!)
                : '-',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Početno očitanje',
            value: '${meter.initialReading.toStringAsFixed(2)} m³',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Zadnje očitanje',
            value: '${meter.lastReading.toStringAsFixed(2)} m³',
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.accent});

  final CustomerWaterMeterStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasUnpaid = stats.unpaidCount > 0;
    final period =
        stats.lastBillingPeriodFrom != null && stats.lastBillingPeriodTo != null
        ? '${_formatDate(stats.lastBillingPeriodFrom!)} - ${_formatDate(stats.lastBillingPeriodTo!)}'
        : '-';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Statistika',
            icon: Icons.insights_outlined,
            color: accent,
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Zadnje očitanje (m³)',
            value: '${stats.lastReading.toStringAsFixed(2)} m³',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Prosječna potrošnja po obračunskom periodu (m³)',
            value: '${stats.averageConsumptionM3.toStringAsFixed(2)} m³',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Ukupno potrošeno (m³)',
            value:
                '${stats.totalConsumptionM3.toStringAsFixed(2)} m³ (${stats.invoiceCount} računa)',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Neplaćeno',
            value:
                '${stats.unpaidCount} računa / ${formatMoney(stats.unpaidAmount)} KM',
            valueColor: hasUnpaid ? AppColors.warning : null,
            emphasize: hasUnpaid,
          ),
          const SizedBox(height: 6),
          _KeyValueRow(label: 'Zadnji obračunski period', value: period),
        ],
      ),
    );
  }
}

class _ConsumptionChartCard extends StatelessWidget {
  const _ConsumptionChartCard({required this.stats, required this.accent});

  final CustomerWaterMeterStats stats;
  final Color accent;

  static const double _barAreaHeight = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = stats.recentForChart;
    final maxConsumption = items.fold<double>(
      0,
      (max, invoice) =>
          invoice.consumptionM3 > max ? invoice.consumptionM3 : max,
    );

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Potrošnja po periodima',
            icon: Icons.bar_chart_outlined,
            color: accent,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty || maxConsumption <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nema podataka o potrošnji.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final invoice in items)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            invoice.consumptionM3.toStringAsFixed(1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: _barAreaHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor:
                                    (invoice.consumptionM3 / maxConsumption)
                                        .clamp(0.02, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _shade(AppColors.secondary, 0.16),
                                        _shade(AppColors.secondary, -0.20),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatMonthYear(invoice.billingPeriodFrom),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Tints [c] toward white for a positive [percent] or toward black for a
  /// negative one - same approach as `_shade` in
  /// customer_water_meters_screen.dart, used here for the bar gradient.
  static Color _shade(Color c, double percent) {
    if (percent >= 0) return Color.lerp(c, Colors.white, percent)!;
    return Color.lerp(c, Colors.black, -percent)!;
  }

  static String _formatMonthYear(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$month/$year';
  }
}

/// This meter's own invoices, newest first (already sorted server-side by
/// `fetchAllForMeter` - no re-sort here), every status - not just unpaid
/// ones. Reuses the shared `InvoiceSummaryCard` rather than nesting each
/// card inside another bordered `_SectionCard`, since the card already
/// carries its own border/shadow/gradient treatment.
class _InvoicesSection extends StatelessWidget {
  const _InvoicesSection({
    required this.invoices,
    required this.accent,
    required this.onOpenInvoice,
  });

  final List<CustomerInvoice> invoices;
  final Color accent;
  final ValueChanged<CustomerInvoice> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Računi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${invoices.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              message: 'Za ovaj vodomjer još nema izdatih računa.',
            ),
          )
        else
          for (var i = 0; i < invoices.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            InvoiceSummaryCard(
              invoice: invoices[i],
              onTap: () => onOpenInvoice(invoices[i]),
            ),
          ],
      ],
    );
  }
}

/// Mirrors `_SectionCard` in customer_invoice_detail_screen.dart so this
/// screen's sections use the same rounded/bordered/shadowed card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE1EDF7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Mirrors `_SectionHeading` in customer_invoice_detail_screen.dart.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Placeholder card shown by `ListSkeleton` while the meter's invoices are
/// loading - shimmered by `Skeletonizer`, so the exact text does not matter,
/// only the layout shape.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeading(
            'Učitavanje',
            icon: Icons.info_outline,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          _KeyValueRow(label: 'Naselje', value: 'Naselje Primjer'),
          SizedBox(height: 6),
          _KeyValueRow(label: 'Adresa', value: 'Ulica 12'),
          SizedBox(height: 6),
          _KeyValueRow(label: 'Datum ugradnje', value: '01.01.2024.'),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
