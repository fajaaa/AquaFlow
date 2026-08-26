import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_consumption_alert.dart';
import 'package:aquaflow_desktop/services/admin_consumption_alert_exception.dart';
import 'package:aquaflow_desktop/services/admin_consumption_alert_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminConsumptionAlertsScreen extends StatefulWidget {
  const AdminConsumptionAlertsScreen({super.key});

  @override
  State<AdminConsumptionAlertsScreen> createState() =>
      _AdminConsumptionAlertsScreenState();
}

class _AdminConsumptionAlertsScreenState
    extends State<AdminConsumptionAlertsScreen>
    with
        PagedListController<
          AdminConsumptionAlert,
          AdminConsumptionAlertsScreen
        > {
  final AdminConsumptionAlertService _service = AdminConsumptionAlertService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminConsumptionAlert> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetch(page: page, pageSize: pageSize);
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminConsumptionAlertException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  Future<void> _recompute() async {
    await runMutation(
      () => _service.recompute(),
      AppLocalizations.of(context).consumptionAlertsRecomputedSuccess,
    );
  }

  Future<void> _markAsResolved(AdminConsumptionAlert alert) async {
    await runMutation(
      () => _service.markAsResolved(alert.id),
      AppLocalizations.of(context).alertMarkedResolvedSuccess,
    );
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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: ScreenHeader(
              title: loc.consumptionAlertsNavLabel,
              subtitle: loc.consumptionAlertsScreenSubtitle,
              actions: [
                RefreshButton(onRefresh: load, enabled: !mutating),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: loading || mutating ? null : _recompute,
                  icon: const Icon(Icons.troubleshoot_outlined),
                  label: Text(loc.checkAnomaliesButtonLabel),
                ),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(loc)),
          if (!isInitialLoad && error == null)
            PagedTablePaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              loading: loading || mutating,
              onPageChanged: goToPage,
              onPageSizeChanged: setPageSize,
            ),
        ],
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
        icon: Icons.warning_amber_outlined,
        message: loc.consumptionAlertsEmptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 56),
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
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 88,
                    columns: [
                      DataColumn(label: Text(loc.typeFieldLabel)),
                      DataColumn(label: Text(loc.measuredValueColumnLabel)),
                      DataColumn(label: Text(loc.thresholdValueColumnLabel)),
                      DataColumn(label: Text(loc.messageColumnLabel)),
                      DataColumn(label: Text(loc.customerColumnLabel)),
                      DataColumn(label: Text(loc.waterMeterColumnLabel)),
                      DataColumn(label: Text(loc.createdAtColumnLabel)),
                      DataColumn(label: Text(loc.statusFieldLabel)),
                      DataColumn(label: Text(loc.actionsColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(Text(_textOrDash(item.alertType))),
                            DataCell(
                              Text(_formatDecimal(item.measuredValue)),
                            ),
                            DataCell(
                              Text(_formatDecimal(item.thresholdValue)),
                            ),
                            DataCell(_WrappedText(item.message)),
                            DataCell(
                              Text(
                                item.customerFullName.isEmpty
                                    ? '-'
                                    : item.customerFullName,
                              ),
                            ),
                            DataCell(
                              Text(_textOrDash(item.waterMeterSerialNumber)),
                            ),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _ResolvedStatusPill(
                                isResolved: item.isResolved,
                              ),
                            ),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                extraActions: [
                                  IconButton(
                                    tooltip: loc.markAsResolvedTooltip,
                                    onPressed: mutating || item.isResolved
                                        ? null
                                        : () => _markAsResolved(item),
                                    icon: const Icon(
                                      Icons.task_alt_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class _WrappedText extends StatelessWidget {
  const _WrappedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Text(_textOrDash(text), softWrap: true),
    );
  }
}

class _ResolvedStatusPill extends StatelessWidget {
  const _ResolvedStatusPill({required this.isResolved});

  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = isResolved
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB91C1C);
    final label = isResolved ? loc.resolvedStatusLabel : loc.unresolvedStatusLabel;
    final icon = isResolved
        ? Icons.check_circle_outline
        : Icons.error_outline;

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

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}

String _formatDecimal(double value) {
  return value.toStringAsFixed(2);
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
