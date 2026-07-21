import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_activity_log.dart';
import 'package:aquaflow_desktop/admin/services/admin_activity_log_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_activity_log_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';

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
        : 'Došlo je do neočekivane greške.';
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

  String get _title => 'Aktivnosti - ${widget.displayName}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: loading ? null : () => load(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
              child: _buildFilters(),
            ),
            if (loading && !isInitialLoad)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent()),
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

  Widget _buildFilters() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 240,
        child: DropdownButtonFormField<String>(
          initialValue: _eventTypeFilter ?? '',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Događaj',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Svi')),
            for (final option in _eventTypeOptions)
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: loading ? null : (value) => _setEventTypeFilter(value ?? ''),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
        message: 'Korisnik nema zabilježenih aktivnosti.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema aktivnosti za zadane filtere.',
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
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('Događaj')),
                      DataColumn(label: Text('Opis')),
                      DataColumn(label: Text('IP adresa')),
                      DataColumn(label: Text('Vrijeme')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(
                              _EventTypePill(eventType: item.eventType),
                            ),
                            DataCell(
                              SizedBox(
                                width: 320,
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
}

class _EventTypePill extends StatelessWidget {
  const _EventTypePill({required this.eventType});

  final String eventType;

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(eventType, Theme.of(context).colorScheme);
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
              _eventTypeLabel(eventType),
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
const List<_SelectOption> _eventTypeOptions = [
  _SelectOption(value: 'LoginSuccess', label: 'Uspješna prijava'),
  _SelectOption(value: 'LoginFailed', label: 'Neuspješna prijava'),
  _SelectOption(value: 'TokenRefreshed', label: 'Obnova sesije'),
  _SelectOption(value: 'Registered', label: 'Registracija'),
  _SelectOption(value: 'PasswordChanged', label: 'Promjena lozinke'),
  _SelectOption(value: 'AccountUpdated', label: 'Izmjena naloga'),
  _SelectOption(value: 'UserRoleChanged', label: 'Promjena role'),
  _SelectOption(value: 'UserActivated', label: 'Korisnik aktiviran'),
  _SelectOption(value: 'UserDeactivated', label: 'Korisnik deaktiviran'),
  _SelectOption(value: 'UserDeleted', label: 'Korisnik obrisan'),
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

String _eventTypeLabel(String type) {
  switch (type) {
    case 'LoginSuccess':
      return 'Uspješna prijava';
    case 'LoginFailed':
      return 'Neuspješna prijava';
    case 'TokenRefreshed':
      return 'Obnova sesije';
    case 'Registered':
      return 'Registracija';
    case 'PasswordChanged':
      return 'Promjena lozinke';
    case 'AccountUpdated':
      return 'Izmjena naloga';
    case 'UserRoleChanged':
      return 'Promjena role';
    case 'UserActivated':
      return 'Korisnik aktiviran';
    case 'UserDeactivated':
      return 'Korisnik deaktiviran';
    case 'UserDeleted':
      return 'Korisnik obrisan';
    default:
      return type.isEmpty ? 'Aktivnost' : type;
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
