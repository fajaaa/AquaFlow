import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_activity_log.dart';
import 'package:aquaflow_desktop/services/admin_activity_log_exception.dart';
import 'package:aquaflow_desktop/services/admin_activity_log_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';

/// Read-only audit trail of a single user's `ActivityLog` rows, pushed from
/// the "Aktivnosti" row action on [AdminUsersScreen] (both modes) and
/// [AdminCollectorsScreen] (same navigation pattern as
/// [AdminUserWaterMetersScreen]). Takes a raw [userId] + [displayName] rather
/// than a model so any listing that knows the linked user's id can push it.
/// Reads `/ActivityLogs` pinned to [userId] (requires `ActivityLogs.Read`,
/// held by the Admin role); there is no create/edit/delete here - rows are
/// only ever written server-side via `ActivityLogService.LogAsync`.
class AdminUserActivityLogsScreen extends StatefulWidget {
  const AdminUserActivityLogsScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final int userId;

  /// Already-resolved label for the app bar (callers pick their own
  /// name/email/code fallback).
  final String displayName;

  @override
  State<AdminUserActivityLogsScreen> createState() =>
      _AdminUserActivityLogsScreenState();
}

class _AdminUserActivityLogsScreenState
    extends State<AdminUserActivityLogsScreen>
    with PagedListController<AdminActivityLog, AdminUserActivityLogsScreen> {
  final AdminActivityLogService _service = AdminActivityLogService();

  String? _eventTypeFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminActivityLog> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      userId: widget.userId,
      eventType: _eventTypeFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminActivityLogException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  void _setEventTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _eventTypeFilter) return;
    setState(() => _eventTypeFilter = selected);
    load(resetPage: true);
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  String _title(AppLocalizations loc) =>
      loc.activityLogTitle(widget.displayName);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(loc)),
        actions: [
          RefreshButton(onRefresh: () => load()),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
              child: _buildFilters(loc),
            ),
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

  Widget _buildFilters(AppLocalizations loc) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 240,
        child: DropdownButtonFormField<String>(
          initialValue: _eventTypeFilter ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.eventTypeFieldLabel,
            prefixIcon: const Icon(Icons.category_outlined),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(loc.allOption)),
            for (final option in _eventTypeOptions(loc))
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: loading
              ? null
              : (value) => _setEventTypeFilter(value ?? ''),
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
        icon: Icons.history_toggle_off,
        message: loc.userNoActivityMessage,
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.activitiesEmptyFilteredMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only "Opis" grows with window width - the other three columns
        // stay sized to their (short, fairly constant) content. 420 is a
        // rough reservation for those columns plus DataTable's default
        // column spacing/margins; the horizontal scroll fallback below
        // covers any underestimate on narrow windows.
        final descriptionWidth = (constraints.maxWidth - 56 - 420).clamp(
          280.0,
          900.0,
        );
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
                    showCheckboxColumn: false,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    columns: [
                      DataColumn(label: Text(loc.eventTypeFieldLabel)),
                      DataColumn(label: Text(loc.descriptionColumnLabel)),
                      DataColumn(label: Text(loc.ipAddressColumnLabel)),
                      DataColumn(label: Text(loc.timeColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) =>
                              _showActivityDetailsDialog(context, item),
                          cells: [
                            DataCell(_EventTypePill(eventType: item.eventType)),
                            DataCell(
                              SizedBox(
                                width: descriptionWidth,
                                child: Text(
                                  _valueOrDash(item.description),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(_valueOrDash(item.ipAddress))),
                            DataCell(Text(_formatDate(item.createdAt))),
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

  bool get _hasFilters => _eventTypeFilter != null;

  Future<void> _showActivityDetailsDialog(
    BuildContext context,
    AdminActivityLog item,
  ) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600);
    final loc = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: _EventTypePill(eventType: item.eventType),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.descriptionColumnLabel, style: labelStyle),
                const SizedBox(height: 4),
                SelectableText(_valueOrDash(item.description)),
                const SizedBox(height: 16),
                Text(loc.ipAddressColumnLabel, style: labelStyle),
                const SizedBox(height: 4),
                SelectableText(_valueOrDash(item.ipAddress)),
                const SizedBox(height: 16),
                Text(loc.timeColumnLabel, style: labelStyle),
                const SizedBox(height: 4),
                Text(_formatDate(item.createdAt)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.commonClose),
          ),
        ],
      ),
    );
  }
}

class _EventTypePill extends StatelessWidget {
  const _EventTypePill({required this.eventType});

  final String eventType;

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(eventType, Theme.of(context).colorScheme);
    final loc = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_eventTypeIcon(eventType), size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _eventTypeLabel(eventType, loc),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

// Same event types as AquaFlow.Model.ActivityEventTypes / the mobile
// "Moje aktivnosti" screen - keep both mappings in sync if a type is added.
// UserRoleChanged/UserActivated/UserDeactivated/UserDeleted are admin actions
// performed on another user's account (UsersController), so they show up here
// (the admin listing) but never on the mobile self-service screen.
List<_SelectOption> _eventTypeOptions(AppLocalizations loc) => [
  _SelectOption(value: 'LoginSuccess', label: loc.activityTypeLoginSuccess),
  _SelectOption(value: 'LoginFailed', label: loc.activityTypeLoginFailed),
  _SelectOption(value: 'TokenRefreshed', label: loc.activityTypeTokenRefreshed),
  _SelectOption(value: 'Registered', label: loc.registerTitle),
  _SelectOption(
    value: 'PasswordChanged',
    label: loc.activityTypePasswordChanged,
  ),
  _SelectOption(value: 'AccountUpdated', label: loc.activityTypeAccountUpdated),
  _SelectOption(
    value: 'UserRoleChanged',
    label: loc.activityTypeUserRoleChanged,
  ),
  _SelectOption(value: 'UserActivated', label: loc.activityTypeUserActivated),
  _SelectOption(
    value: 'UserDeactivated',
    label: loc.activityTypeUserDeactivated,
  ),
  _SelectOption(value: 'UserDeleted', label: loc.activityTypeUserDeleted),
];

IconData _eventTypeIcon(String type) {
  switch (type) {
    case 'LoginSuccess':
      return Icons.login;
    case 'LoginFailed':
      return Icons.block_outlined;
    case 'TokenRefreshed':
      return Icons.autorenew;
    case 'Registered':
      return Icons.person_add_alt_outlined;
    case 'PasswordChanged':
      return Icons.lock_reset;
    case 'AccountUpdated':
      return Icons.manage_accounts_outlined;
    case 'UserRoleChanged':
      return Icons.admin_panel_settings_outlined;
    case 'UserActivated':
      return Icons.check_circle_outline;
    case 'UserDeactivated':
      return Icons.remove_circle_outline;
    case 'UserDeleted':
      return Icons.person_remove_outlined;
    default:
      return Icons.history;
  }
}

Color _eventTypeColor(String type, ColorScheme colorScheme) {
  switch (type) {
    case 'LoginSuccess':
      return const Color(0xFF2E7D32);
    case 'LoginFailed':
      return colorScheme.error;
    case 'TokenRefreshed':
      return const Color(0xFF0277BD);
    case 'Registered':
      return const Color(0xFF0277BD);
    case 'PasswordChanged':
      return const Color(0xFFF9A825);
    case 'AccountUpdated':
      return const Color(0xFF00838F);
    case 'UserRoleChanged':
      return const Color(0xFF6A1B9A);
    case 'UserActivated':
      return const Color(0xFF2E7D32);
    case 'UserDeactivated':
      return const Color(0xFFEF6C00);
    case 'UserDeleted':
      return const Color(0xFFC62828);
    default:
      return colorScheme.primary;
  }
}

String _eventTypeLabel(String type, AppLocalizations loc) {
  switch (type) {
    case 'LoginSuccess':
      return loc.activityTypeLoginSuccess;
    case 'LoginFailed':
      return loc.activityTypeLoginFailed;
    case 'TokenRefreshed':
      return loc.activityTypeTokenRefreshed;
    case 'Registered':
      return loc.registerTitle;
    case 'PasswordChanged':
      return loc.activityTypePasswordChanged;
    case 'AccountUpdated':
      return loc.activityTypeAccountUpdated;
    case 'UserRoleChanged':
      return loc.activityTypeUserRoleChanged;
    case 'UserActivated':
      return loc.activityTypeUserActivated;
    case 'UserDeactivated':
      return loc.activityTypeUserDeactivated;
    case 'UserDeleted':
      return loc.activityTypeUserDeleted;
    default:
      return type.isEmpty ? loc.activityTypeGenericLabel : type;
  }
}

String _valueOrDash(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '-' : trimmed;
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
