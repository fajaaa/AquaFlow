import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_activity_log.dart';
import 'package:aquaflow_desktop/admin/models/admin_activity_log_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_activity_log_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_activity_log_service.dart';

/// Read-only admin audit trail over `/ActivityLogs` (requires
/// `ActivityLogs.Read`, held by the Admin role). Unlike
/// [AdminNotificationsScreen] there is no create/edit/delete here - rows are
/// only ever written server-side via `ActivityLogService.LogAsync`.
class AdminActivityLogsScreen extends StatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  State<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState extends State<AdminActivityLogsScreen> {
  final AdminActivityLogService _service = AdminActivityLogService();

  AdminActivityLogPage? _pageData;
  bool _loading = true;
  String? _error;
  String? _eventTypeFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool resetPage = false}) async {
    final requestId = ++_requestSerial;

    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetch(
        page: _page,
        pageSize: _pageSize,
        eventType: _eventTypeFilter,
        from: _fromDate,
        to: _toDateInclusive,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminActivityLogException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  DateTime? get _toDateInclusive {
    final to = _toDate;
    if (to == null) return null;
    return DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
  }

  void _setEventTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _eventTypeFilter) return;
    setState(() => _eventTypeFilter = selected);
    _load(resetPage: true);
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (!mounted || date == null) return;
    setState(() => _fromDate = date);
    _load(resetPage: true);
  }

  void _clearFromDate() {
    if (_fromDate == null) return;
    setState(() => _fromDate = null);
    _load(resetPage: true);
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (!mounted || date == null) return;
    setState(() => _toDate = date);
    _load(resetPage: true);
  }

  void _clearToDate() {
    if (_toDate == null) return;
    setState(() => _toDate = null);
    _load(resetPage: true);
  }

  void _setPageSize(int? value) {
    if (value == null || value == _pageSize || _loading) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    _load();
  }

  void _goToPage(int page) {
    if (page == _page || _loading) return;
    setState(() => _page = page);
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(loading: _loading, onRefresh: () => _load()),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if (_loading && pageData != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          if (pageData != null && _error == null)
            _PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalCount: pageData.totalCount,
              pageSize: _pageSize,
              loading: _loading,
              onPageChanged: _goToPage,
              onPageSizeChanged: _setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _eventTypeFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Događaj',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final option in _eventTypeOptions)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: _loading ? null : (value) => _setEventTypeFilter(value ?? ''),
          ),
        ),
        _DateFilterField(
          label: 'Od datuma',
          value: _fromDate,
          enabled: !_loading,
          onPick: _pickFromDate,
          onClear: _fromDate == null ? null : _clearFromDate,
        ),
        _DateFilterField(
          label: 'Do datuma',
          value: _toDate,
          enabled: !_loading,
          onPick: _pickToDate,
          onClear: _toDate == null ? null : _clearToDate,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading && _pageData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: () => _load());
    }

    final items = _pageData?.items ?? const <AdminActivityLog>[];
    if (items.isEmpty) {
      return _EmptyState(hasFilters: _hasFilters);
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
                      DataColumn(label: Text('Korisnik')),
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
                              SizedBox(
                                width: 220,
                                child: Text(
                                  item.userEmail.isEmpty
                                      ? '-'
                                      : item.userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
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

  bool get _hasFilters =>
      _eventTypeFilter != null || _fromDate != null || _toDate != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.loading, required this.onRefresh});

  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivnosti',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled sigurnosnih i korisničkih aktivnosti u sistemu.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = IconButton(
      tooltip: 'Osvježi',
      onPressed: loading ? null : onRefresh,
      icon: const Icon(Icons.refresh),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onPick : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.event_outlined),
            suffixIcon: value != null
                ? IconButton(
                    tooltip: 'Očisti',
                    onPressed: enabled ? onClear : null,
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          child: Text(value == null ? '-' : _formatDateOnly(value!)),
        ),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.loading,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool loading;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = page > 1 && !loading;
    final canGoForward = page < totalPages && !loading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Prethodna stranica',
                            onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              'Str. $page/$totalPages',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sljedeća stranica',
                            onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalCount ukupno',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: pageSize,
                                onChanged: loading ? null : onPageSizeChanged,
                                items: const [
                                  DropdownMenuItem(value: 10, child: Text('10')),
                                  DropdownMenuItem(value: 20, child: Text('20')),
                                  DropdownMenuItem(value: 50, child: Text('50')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        tooltip: 'Prethodna stranica',
                        onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          'Stranica $page od $totalPages · $totalCount ukupno',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sljedeća stranica',
                        onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: pageSize,
                          onChanged: loading ? null : onPageSizeChanged,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 20, child: Text('20')),
                            DropdownMenuItem(value: 50, child: Text('50')),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.history_toggle_off,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'Nema aktivnosti za zadane filtere.'
                : 'Nema zabilježenih aktivnosti.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
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

String _formatDateOnly(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
