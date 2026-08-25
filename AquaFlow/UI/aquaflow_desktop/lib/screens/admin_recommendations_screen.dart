import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_recommendation.dart';
import 'package:aquaflow_desktop/services/admin_recommendation_exception.dart';
import 'package:aquaflow_desktop/services/admin_recommendation_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminRecommendationsScreen extends StatefulWidget {
  const AdminRecommendationsScreen({super.key});

  @override
  State<AdminRecommendationsScreen> createState() =>
      _AdminRecommendationsScreenState();
}

class _AdminRecommendationsScreenState
    extends State<AdminRecommendationsScreen>
    with PagedListController<AdminRecommendation, AdminRecommendationsScreen> {
  final AdminRecommendationService _service = AdminRecommendationService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminRecommendation> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetch(page: page, pageSize: pageSize);
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminRecommendationException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  Future<void> _recompute() async {
    await runMutation(
      () => _service.recompute(),
      AppLocalizations.of(context).recommendationsRecomputedSuccess,
    );
  }

  Future<void> _markAsRead(AdminRecommendation recommendation) async {
    await runMutation(
      () => _service.markAsRead(recommendation.id),
      AppLocalizations.of(context).recommendationMarkedReadSuccess,
    );
  }

  Future<void> _confirmDelete(AdminRecommendation recommendation) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteRecommendationDialogTitle),
        content: Text(loc.deleteRecommendationDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.dialogDismissButton),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(loc.commonDelete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.delete(recommendation.id);
      if (items.length == 1 && page > 1) {
        page -= 1;
      }
    }, loc.recommendationDeletedSuccess);
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
              title: loc.recommendationsNavLabel,
              subtitle: loc.recommendationsScreenSubtitle,
              actions: [
                RefreshButton(onRefresh: load, enabled: !mutating),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: loading || mutating ? null : _recompute,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(loc.refreshRecommendationsButtonLabel),
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
        icon: Icons.tips_and_updates_outlined,
        message: loc.recommendationsEmptyMessage,
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
                      DataColumn(label: Text(loc.messageColumnLabel)),
                      DataColumn(label: Text(loc.reasonColumnLabel)),
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
                            DataCell(Text(_textOrDash(item.type))),
                            DataCell(_WrappedText(item.message)),
                            DataCell(_WrappedText(item.reason)),
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
                            DataCell(_ReadStatusPill(isRead: item.isRead)),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                onDelete: () => _confirmDelete(item),
                                extraActions: [
                                  IconButton(
                                    tooltip: loc.markAsReadTooltip,
                                    onPressed: mutating || item.isRead
                                        ? null
                                        : () => _markAsRead(item),
                                    icon: const Icon(
                                      Icons.mark_email_read_outlined,
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

class _ReadStatusPill extends StatelessWidget {
  const _ReadStatusPill({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = isRead ? const Color(0xFF2E7D32) : const Color(0xFFB45309);
    final label = isRead ? loc.readStatusLabel : loc.unreadStatusLabel;
    final icon = isRead
        ? Icons.check_circle_outline
        : Icons.mark_email_unread_outlined;

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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
