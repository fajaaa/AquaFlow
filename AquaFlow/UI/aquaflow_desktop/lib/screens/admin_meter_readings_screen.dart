import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/models/admin_meter_reading.dart';
import 'package:aquaflow_desktop/services/admin_meter_reading_exception.dart';
import 'package:aquaflow_desktop/services/admin_meter_reading_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';

class AdminMeterReadingsScreen extends StatefulWidget {
  const AdminMeterReadingsScreen({
    super.key,
    required this.waterMeterId,
    required this.waterMeterSerialNumber,
  });

  final int waterMeterId;
  final String waterMeterSerialNumber;

  @override
  State<AdminMeterReadingsScreen> createState() =>
      _AdminMeterReadingsScreenState();
}

class _AdminMeterReadingsScreenState extends State<AdminMeterReadingsScreen>
    with PagedListController<AdminMeterReading, AdminMeterReadingsScreen> {
  final AdminMeterReadingService _service = AdminMeterReadingService();

  List<AdminCollectorProfile> _collectors = const [];

  @override
  void initState() {
    super.initState();
    load();
    _loadCollectors();
  }

  Future<void> _loadCollectors() async {
    try {
      final collectors = await _service.fetchCollectors();
      if (!mounted) return;
      setState(() => _collectors = collectors);
    } catch (_) {
      // Non-fatal: the table falls back to "Inkasant #<id>" per row.
    }
  }

  String _collectorLabel(int collectorId) {
    for (final collector in _collectors) {
      if (collector.id == collectorId) return collector.label;
    }
    return AppLocalizations.of(
      context,
    ).collectorNumberFallbackLabel(collectorId);
  }

  @override
  Future<({List<AdminMeterReading> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetchForWaterMeter(
      waterMeterId: widget.waterMeterId,
      page: page,
      pageSize: pageSize,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminMeterReadingException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.meterReadingsTitle(widget.waterMeterSerialNumber)),
        actions: [
          RefreshButton(onRefresh: () => load(), enabled: !loading),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading && !isInitialLoad)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent(loc)),
            if (!isInitialLoad && error == null)
              PagedTablePaginationBar(
                page: page,
                totalPages: totalPages,
                totalCount: totalCount,
                pageSize: pageSize,
                loading: loading,
                onPageChanged: goToPage,
                onPageSizeChanged: setPageSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }

    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.speed_outlined,
        message: loc.noReadingsForMeterMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 40),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.30),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    columns: [
                      DataColumn(label: Text(loc.readingDateColumnLabel)),
                      DataColumn(
                        label: Text(loc.previousReadingColumnLabel),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(loc.newReadingColumnLabel),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(loc.consumptionColumnLabel),
                        numeric: true,
                      ),
                      DataColumn(label: Text(loc.collectorNameColumnLabel)),
                      DataColumn(label: Text(loc.syncColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(Text(_formatDateTime(item.readingDate))),
                            DataCell(
                              Text(_formatReading(item.previousReadingValue)),
                            ),
                            DataCell(Text(_formatReading(item.readingValue))),
                            DataCell(Text(_formatReading(item.consumptionM3))),
                            DataCell(Text(_collectorLabel(item.collectorId))),
                            DataCell(_SyncStatusPill(status: item.syncStatus)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final (label, color, icon) = switch (status.toLowerCase()) {
      'synced' => (
        loc.syncStatusSynced,
        const Color(0xFF2E7D32),
        Icons.cloud_done_outlined,
      ),
      'pending' => (
        loc.requestStatusPending,
        const Color(0xFFB45309),
        Icons.cloud_upload_outlined,
      ),
      'failed' => (
        loc.syncStatusFailed,
        const Color(0xFFB91C1C),
        Icons.cloud_off_outlined,
      ),
      _ => (
        status.isEmpty ? '-' : status,
        const Color(0xFF64748B),
        Icons.help_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}

String _formatReading(double value) {
  return value.toStringAsFixed(2);
}
