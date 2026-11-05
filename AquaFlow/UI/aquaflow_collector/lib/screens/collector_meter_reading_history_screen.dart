import 'package:flutter/material.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/models/collector_meter_reading.dart';
import 'package:aquaflow_collector/models/collector_water_meter.dart';
import 'package:aquaflow_collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_collector/services/collector_meter_reading_service.dart';
import 'package:aquaflow_collector/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_collector/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_collector/shared/widgets/error_retry.dart';
import 'package:aquaflow_collector/shared/widgets/list_skeleton.dart';

/// Reading history of one water meter (newest first). Always loads fresh on
/// open; pull-to-refresh reloads the current page.
class CollectorMeterReadingHistoryScreen extends StatefulWidget {
  const CollectorMeterReadingHistoryScreen({super.key, required this.meter});

  final CollectorWaterMeter meter;

  @override
  State<CollectorMeterReadingHistoryScreen> createState() =>
      _CollectorMeterReadingHistoryScreenState();
}

class _CollectorMeterReadingHistoryScreenState
    extends State<CollectorMeterReadingHistoryScreen>
    with PagedListController<CollectorMeterReading,
        CollectorMeterReadingHistoryScreen> {
  final CollectorMeterReadingService _service = CollectorMeterReadingService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<CollectorMeterReading> items, int totalCount})> fetchPage() =>
      _service.fetchHistory(
        waterMeterId: widget.meter.id,
        page: page,
        pageSize: pageSize,
      );

  @override
  String describeError(Object error) => error is CollectorMeterReadingException
      ? error.message
      : error.toString();

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final meter = widget.meter;
    final subtitle = [
      meter.settlementName,
      meter.address,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(loc.readingHistoryTitle)),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              serial: meter.serialNumber,
              owner: meter.customerFullName,
              address: subtitle,
            ),
            Expanded(child: _buildContent(loc)),
            if (!isInitialLoad && error == null && totalPages > 1)
              _Pager(
                page: page,
                totalPages: totalPages,
                busy: loading,
                onPage: goToPage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    if (isInitialLoad) {
      return ListSkeleton(
        itemBuilder: (context, index) => _ReadingCard(
          reading: CollectorMeterReading(
            id: 0,
            readingDate: DateTime(2000),
            readingValue: 0,
            note: 'Napomena',
          ),
        ),
      );
    }

    final err = error;
    if (err != null) {
      return ErrorRetry(message: err, onRetry: load);
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            EmptyStateView(
              icon: Icons.history,
              message: loc.readingHistoryEmptyMessage,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ReadingCard(reading: items[index]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.serial,
    required this.owner,
    required this.address,
  });

  final String serial;
  final String owner;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serial,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (owner.isNotEmpty)
            Text(owner, style: theme.textTheme.bodyMedium),
          if (address.isNotEmpty)
            Text(
              address,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading});

  final CollectorMeterReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final voided = reading.voidedAt != null;
    final note = reading.note?.trim() ?? '';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(reading.readingDate),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (voided) _VoidedPill(label: loc.readingHistoryVoidedPill),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_num(reading.previousReadingValue)} → '
              '${_num(reading.readingValue)}',
              style: theme.textTheme.titleMedium?.copyWith(
                decoration: voided ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.readingHistoryConsumption(_num(reading.consumptionM3)),
              style: theme.textTheme.bodyMedium,
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoidedPill extends StatelessWidget {
  const _VoidedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.busy,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final bool busy;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 && !busy ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(loc.readingHistoryPageIndicator(page, totalPages)),
        IconButton(
          onPressed: page < totalPages && !busy ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

String _num(double value) =>
    value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}. '
      '${two(local.hour)}:${two(local.minute)}';
}
