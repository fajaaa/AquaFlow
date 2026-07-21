import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_support_ticket.dart';
import 'package:aquaflow_desktop/admin/models/admin_support_ticket_page.dart';
import 'package:aquaflow_desktop/admin/screens/admin_support_ticket_detail_screen.dart';
import 'package:aquaflow_desktop/admin/services/admin_support_ticket_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_support_ticket_service.dart';
import 'package:aquaflow_desktop/admin/widgets/support_ticket_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';

const Color _awaitingReplyColor = Color(0xFFF9A825);

const _statusOptions = <String, String>{
  'Open': 'Otvoreni',
  'Closed': 'Zatvoreni',
};

/// Admin table over `/SupportTickets` (`AdminSupportTicketService`/`AdminSupportTicket`
/// data layer) - every customer's ticket, not just the signed-in admin's, same
/// `SupportTickets.Manage`-gated shape as `ActivityLogsController.GetAll`.
/// Follows the `AdminPaymentsScreen`/`AdminFaultReportsScreen` template
/// (`_requestSerial`/450ms-debounce/paging, read-only - no `_runMutation`,
/// since the only mutations (reply/close/reopen) happen on the detail thread,
/// not here). Filters are Status (Svi/Otvoreni/Zatvoreni) and a debounced
/// Subject search (`Term`); the list defaults to `LastMessageAt` descending
/// (the backend default, sent explicitly by the service). Rows whose newest
/// message is not a staff reply (`AdminSupportTicket.awaitingReply`) are
/// tinted and get an unread-mail icon next to the subject, so an admin can
/// spot tickets waiting on a response at a glance. Tapping a row pushes
/// `AdminSupportTicketDetailScreen` - the same chat thread the customer sees,
/// plus a staff reply composer and Close/Reopen actions.
class AdminSupportTicketsScreen extends StatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  State<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState
    extends State<AdminSupportTicketsScreen> {
  final AdminSupportTicketService _service = AdminSupportTicketService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminSupportTicketPage? _pageData;
  bool _loading = true;
  String? _error;
  String? _statusFilter;
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
        term: _searchCtrl.text,
        status: _statusFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminSupportTicketException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _queueSearch(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _load(resetPage: true),
    );
  }

  void _submitSearch(String _) {
    _searchDebounce?.cancel();
    _load(resetPage: true);
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {});
    _load(resetPage: true);
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
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

  Future<void> _openDetail(AdminSupportTicket ticket) async {
    await context.pushScreen(AdminSupportTicketDetailScreen(ticketId: ticket.id));
    // A reply or a status change on the detail screen may have moved the
    // ticket in the sort order or its awaiting-reply state, so refresh.
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _queueSearch,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Pretraga',
              hintText: 'Predmet tiketa',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearch
                  ? IconButton(
                      tooltip: 'Očisti pretragu',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final entry in _statusOptions.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: _loading ? null : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filtere',
          onPressed: _loading ? null : () => _load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
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

    final items = _pageData?.items ?? const <AdminSupportTicket>[];
    if (items.isEmpty) {
      return _EmptyState(hasFilters: _hasFilters);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;

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
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 72,
                    columns: [
                      const DataColumn(label: Text('Predmet')),
                      if (!isSmallScreen) const DataColumn(label: Text('Kupac')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Poruke')),
                      const DataColumn(label: Text('Zadnja poruka')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          color: item.awaitingReply
                              ? WidgetStateProperty.all(
                                  _awaitingReplyColor.withValues(alpha: 0.08),
                                )
                              : null,
                          onSelectChanged: (_) => _openDetail(item),
                          cells: [
                            DataCell(_SubjectCell(item: item)),
                            if (!isSmallScreen)
                              DataCell(
                                Text(
                                  item.customerName?.trim().isNotEmpty == true
                                      ? item.customerName!.trim()
                                      : '#${item.customerId}',
                                ),
                              ),
                            DataCell(SupportTicketStatusPill(status: item.status)),
                            DataCell(Text('${item.messageCount}')),
                            DataCell(Text(_formatDate(item.lastMessageAt))),
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
      _searchCtrl.text.trim().isNotEmpty || _statusFilter != null;

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
          'Podrška',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Svi korisnički tiketi podrške. Tiketi označeni narandžastom '
          'čekaju odgovor - zadnja poruka u niti nije od podrške.',
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

class _SubjectCell extends StatelessWidget {
  const _SubjectCell({required this.item});

  final AdminSupportTicket item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = item.subject.trim().isEmpty
        ? 'Tiket #${item.id}'
        : item.subject.trim();

    return SizedBox(
      width: 280,
      child: Row(
        children: [
          if (item.awaitingReply) ...[
            Icon(
              Icons.mark_chat_unread_outlined,
              size: 16,
              color: _awaitingReplyColor,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: item.awaitingReply
                    ? FontWeight.w700
                    : FontWeight.w500,
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
            hasFilters ? Icons.search_off : Icons.support_agent_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? 'Nema tiketa za zadane filtere.' : 'Nema tiketa.',
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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
