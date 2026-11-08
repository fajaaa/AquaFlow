import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_consumption_alert.dart';
import 'package:aquaflow_desktop/models/lookup_item.dart';
import 'package:aquaflow_desktop/services/admin_consumption_alert_exception.dart';
import 'package:aquaflow_desktop/services/admin_consumption_alert_service.dart';
import 'package:aquaflow_desktop/services/admin_lookup_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';

const Color _openColor = Color(0xFFB91C1C);
const Color _resolvedColor = Color(0xFF2E7D32);
const Color _amberColor = Color(0xFFB45309);

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

  // Default view: unresolved alerts only. null = all.
  bool? _resolvedFilter = false;

  // ConsumptionAlertTypes codebook keyed by lower-cased code. Until it loads (or for an
  // unknown code) the raw code is shown.
  Map<String, LookupItem> _alertTypes = const {};

  @override
  void initState() {
    super.initState();
    load();
    _loadAlertTypes();
  }

  Future<void> _loadAlertTypes() async {
    try {
      final types = await AdminLookupService().fetchActive(
        'ConsumptionAlertTypes',
      );
      if (!mounted) return;
      setState(() {
        _alertTypes = {for (final type in types) type.code.toLowerCase(): type};
      });
    } catch (_) {
      // Keep showing the raw codes.
    }
  }

  String _alertTypeName(String code, String languageCode) {
    final name = _alertTypes[code.trim().toLowerCase()]?.localizedName(
      languageCode,
    );
    return name == null || name.trim().isEmpty ? _textOrDash(code) : name;
  }

  void _setResolvedFilter(String value) {
    final selected = switch (value) {
      'resolved' => true,
      'open' => false,
      _ => null,
    };
    if (selected == _resolvedFilter) return;
    setState(() => _resolvedFilter = selected);
    load(resetPage: true);
  }

  Widget _buildFilters(AppLocalizations loc) {
    final value = switch (_resolvedFilter) {
      false => 'open',
      true => 'resolved',
      null => 'all',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: loc.statusFieldLabel,
              prefixIcon: const Icon(Icons.toggle_on_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'open',
                child: Text(loc.unresolvedStatusLabel),
              ),
              DropdownMenuItem(
                value: 'resolved',
                child: Text(loc.resolvedStatusLabel),
              ),
              DropdownMenuItem(value: 'all', child: Text(loc.allOption)),
            ],
            onChanged: mutating
                ? null
                : (selected) => _setResolvedFilter(selected ?? 'all'),
          ),
        ),
      ),
    );
  }

  @override
  Future<({List<AdminConsumptionAlert> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      isResolved: _resolvedFilter,
    );
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
    // runMutation reloads the current page; if the resolved item was the last
    // one on a trailing page of the Neriješeni view, step back one page.
    if (mounted && items.isEmpty && page > 1 && error == null) {
      setState(() => page = page - 1);
      await load();
    }
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
          _buildFilters(loc),
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

    final languageCode = Localizations.localeOf(context).languageCode;
    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _AlertCard(
            alert: item,
            typeName: _alertTypeName(item.alertType, languageCode),
            onResolve: mutating ? null : () => _markAsResolved(item),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.typeName,
    required this.onResolve,
  });

  final AdminConsumptionAlert alert;
  final String typeName;

  /// Null while a mutation is running; the button is also disabled once resolved.
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final expected = _formatExpected(alert, loc);
    final above = _isAboveExpected(alert);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 22,
                        color: alert.isResolved ? muted : _amberColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          typeName,
                          softWrap: true,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _ResolvedStatusPill(isResolved: alert.isResolved),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(alert.createdAt),
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${alert.customerFullName.isEmpty ? '-' : alert.customerFullName}'
          ' · ${_textOrDash(alert.waterMeterSerialNumber)}',
          softWrap: true,
          style: textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );

    final resolveButton = Tooltip(
      message: loc.markAsResolvedTooltip,
      child: FilledButton.tonalIcon(
        onPressed: alert.isResolved ? null : onResolve,
        icon: const Icon(Icons.task_alt),
        label: Text(loc.markAsResolvedButtonLabel),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Narrow window: the action drops under the header instead of
                // squeezing it.
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 12),
                      resolveButton,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: header),
                    const SizedBox(width: 16),
                    resolveButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Metric(
                  label: loc.measuredValueColumnLabel,
                  child: Text(
                    loc.cubicMetersValue(_formatDecimal(alert.measuredValue)),
                    style: _metricValueStyle(textTheme),
                  ),
                ),
                _Metric(
                  label: loc.expectedColumnLabel,
                  child: expected != null
                      ? Text(expected, style: _metricValueStyle(textTheme))
                      : Tooltip(
                          message: loc.expectedInsufficientHistoryTooltip,
                          child: Text(
                            loc.expectedInsufficientHistory,
                            style: textTheme.bodyMedium?.copyWith(
                              color: muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                ),
                _Metric(
                  label: loc.thresholdValueColumnLabel,
                  child: Text(
                    loc.cubicMetersValue(_formatDecimal(alert.thresholdValue)),
                    style: _metricValueStyle(textTheme),
                  ),
                ),
                if (above != null)
                  _TintedBadge(
                    color: above ? _openColor : _amberColor,
                    icon: above ? Icons.arrow_upward : Icons.arrow_downward,
                    label: above
                        ? loc.alertAboveExpectedLabel
                        : loc.alertBelowExpectedLabel,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _textOrDash(alert.message),
              softWrap: true,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _metricValueStyle(TextTheme textTheme) =>
    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

class _ResolvedStatusPill extends StatelessWidget {
  const _ResolvedStatusPill({required this.isResolved});

  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return _TintedBadge(
      color: isResolved ? _resolvedColor : _openColor,
      icon: isResolved ? Icons.check_circle_outline : Icons.error_outline,
      label: isResolved ? loc.resolvedStatusLabel : loc.unresolvedStatusLabel,
    );
  }
}

/// Small tinted icon + label badge shared by the status pill and the direction chip.
class _TintedBadge extends StatelessWidget {
  const _TintedBadge({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
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

/// "X m³ (Y-Z)" from the model's expectation and 95 % interval, or null when the
/// model had too little history to produce one.
String? _formatExpected(AdminConsumptionAlert item, AppLocalizations loc) {
  final expected = item.expectedValue;
  final lower = item.expectedLowerBound;
  final upper = item.expectedUpperBound;
  if (expected == null || lower == null || upper == null) return null;
  return loc.expectedRangeValue(
    _formatDecimal(expected),
    _formatDecimal(lower),
    _formatDecimal(upper),
  );
}

/// Whether the measured value is above (true) or below (false) the model's
/// expectation, or the previous-readings average when there is none; null when
/// they are equal.
bool? _isAboveExpected(AdminConsumptionAlert item) {
  final reference = item.expectedValue ?? item.thresholdValue;
  if (item.measuredValue == reference) return null;
  return item.measuredValue > reference;
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
