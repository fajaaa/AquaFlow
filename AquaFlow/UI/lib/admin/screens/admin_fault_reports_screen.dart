import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_fault_report.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report_photo.dart';
import 'package:aquaflow_desktop/admin/services/admin_fault_report_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_fault_report_service.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';

/// Desktop admin table over `/FaultReports` (`AdminFaultReportService`/
/// `AdminFaultReport` data layer). Same `_requestSerial`/450ms-debounce/
/// `_runMutation`/paging template as `AdminInvoicesScreen`/`AdminTariffsScreen`.
/// Row click opens a detail dialog with the full description and a photo
/// gallery; a row action advances the status (New -> InProgress -> Resolved,
/// via the backend transition endpoints `POST {id}/start`/`{id}/resolve` -
/// the server stamps `resolvedAt` itself) behind the confirm-dialog pattern
/// used by `AdminTariffsScreen`'s delete confirmation.
class AdminFaultReportsScreen extends StatefulWidget {
  const AdminFaultReportsScreen({super.key});

  @override
  State<AdminFaultReportsScreen> createState() =>
      _AdminFaultReportsScreenState();
}

const _statusOptions = <String, String>{
  'New': 'Nova',
  'InProgress': 'U toku',
  'Resolved': 'Riješena',
};

class _AdminFaultReportsScreenState extends State<AdminFaultReportsScreen> {
  final AdminFaultReportService _service = AdminFaultReportService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminFaultReportPage? _pageData;
  bool _loading = true;
  bool _mutating = false;
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
    } on AdminFaultReportException catch (e) {
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

  void _openDetail(AdminFaultReport report) {
    showDialog<void>(
      context: context,
      builder: (_) => _FaultReportDetailDialog(report: report, service: _service),
    );
  }

  Future<void> _advanceStatus(AdminFaultReport report) async {
    final next = _nextStatus(report.status);
    if (next == null) return;

    final confirmed = await _confirmAction(
      title: 'Promijeni status',
      message:
          'Da li želite promijeniti status prijave "${report.title}" u '
          '"${_statusOptions[next] ?? next}"?',
      confirmLabel: 'Promijeni',
      icon: _statusIcon(next),
    );
    if (!mounted || confirmed != true) return;

    // New -> start, InProgress -> resolve; the backend state machine stamps
    // resolvedAt itself, so no date is sent from here anymore.
    await _runMutation(() async {
      if (report.status == 'New') {
        await _service.start(report.id);
      } else {
        await _service.resolve(report.id);
      }
    }, 'Status prijave je promijenjen.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(icon),
            label: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _load();
    } on AdminFaultReportException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
                _Header(
                  loading: _loading,
                  mutating: _mutating,
                  onRefresh: () => _load(),
                ),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if ((_loading && pageData != null) || _mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          if (pageData != null && _error == null)
            _PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalCount: pageData.totalCount,
              pageSize: _pageSize,
              loading: _loading || _mutating,
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
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _queueSearch,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Naslov, kupac ili naselje',
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
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final entry in _statusOptions.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filtere',
          onPressed: _loading || _mutating
              ? null
              : () => _load(resetPage: true),
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

    final items = _pageData?.items ?? const <AdminFaultReport>[];
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
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
                    columns: const [
                      DataColumn(label: Text('Naslov')),
                      DataColumn(label: Text('Kupac')),
                      DataColumn(label: Text('Naselje')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Datum')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openDetail(item),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  item.title.isEmpty ? '-' : item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(item.customerFullName)),
                            DataCell(Text(item.settlementName)),
                            DataCell(_StatusPill(status: item.status)),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _RowActions(
                                report: item,
                                disabled: _mutating,
                                onAdvanceStatus: () => _advanceStatus(item),
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

  bool get _hasFilters =>
      _searchCtrl.text.trim().isNotEmpty || _statusFilter != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

String? _nextStatus(String status) {
  switch (status) {
    case 'New':
      return 'InProgress';
    case 'InProgress':
      return 'Resolved';
    default:
      return null;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'InProgress':
      return Icons.engineering_outlined;
    case 'Resolved':
      return Icons.check_circle_outline;
    default:
      return Icons.fiber_new_outlined;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.loading,
    required this.mutating,
    required this.onRefresh,
  });

  final bool loading;
  final bool mutating;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prijave kvarova',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled prijava kvarova i upravljanje statusom.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = IconButton(
      tooltip: 'Osvježi',
      onPressed: loading || mutating ? null : onRefresh,
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

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.report,
    required this.disabled,
    required this.onAdvanceStatus,
  });

  final AdminFaultReport report;
  final bool disabled;
  final VoidCallback onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(report.status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: next == null
              ? 'Prijava je riješena'
              : 'Promijeni status u "${_statusOptions[next] ?? next}"',
          onPressed: disabled || next == null ? null : onAdvanceStatus,
          icon: Icon(_statusIcon(next ?? report.status)),
        ),
      ],
    );
  }
}

/// Coloured status pill: New=slate, InProgress=amber, Resolved=green - same
/// color token pattern as `_InvoiceStatusPill`.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'New' => ('Nova', const Color(0xFF64748B), Icons.fiber_new_outlined),
      'InProgress' => (
        'U toku',
        const Color(0xFFB45309),
        Icons.engineering_outlined,
      ),
      'Resolved' => (
        'Riješena',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      _ => (status, const Color(0xFF64748B), Icons.help_outline),
    };

    return _Pill(label: label, color: color, icon: icon);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

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

/// Full detail view of a fault report, opened from a row click. Fetches the
/// photo gallery lazily (`GET /FaultReports/{id}/photos`) and renders each
/// thumbnail through the shared `AuthenticatedImage` widget; tapping one opens
/// a fullscreen preview, same pattern as `CustomerFaultReportDetailScreen`.
class _FaultReportDetailDialog extends StatefulWidget {
  const _FaultReportDetailDialog({required this.report, required this.service});

  final AdminFaultReport report;
  final AdminFaultReportService service;

  @override
  State<_FaultReportDetailDialog> createState() =>
      _FaultReportDetailDialogState();
}

class _FaultReportDetailDialogState extends State<_FaultReportDetailDialog> {
  bool _loading = true;
  String? _error;
  List<AdminFaultReportPhoto> _photos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final photos = await widget.service.fetchPhotos(widget.report.id);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } on AdminFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _openFullscreen(AdminFaultReportPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenPhotoScreen(
          fileName: photo.fileName,
          fetcher: () =>
              widget.service.fetchPhotoBytes(widget.report.id, photo.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(report.title.isEmpty ? '-' : report.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusPill(status: report.status),
              const SizedBox(height: 14),
              _KeyValueRow(label: 'Kupac', value: report.customerFullName),
              const SizedBox(height: 6),
              _KeyValueRow(label: 'Naselje', value: report.settlementName),
              const SizedBox(height: 6),
              _KeyValueRow(
                label: 'Prijavljeno',
                value: _formatDateTime(report.createdAt),
              ),
              if (report.resolvedAt != null) ...[
                const SizedBox(height: 6),
                _KeyValueRow(
                  label: 'Riješeno',
                  value: _formatDateTime(report.resolvedAt),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Opis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                report.description.isEmpty ? '-' : report.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                'Fotografije',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildPhotos(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }

  Widget _buildPhotos() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    if (_photos.isEmpty) {
      return Text(
        'Nema priloženih fotografija.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _openFullscreen(photo),
          child: AuthenticatedImage(
            fetcher: () =>
                widget.service.fetchPhotoBytes(widget.report.id, photo.id),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _FullscreenPhotoScreen extends StatelessWidget {
  const _FullscreenPhotoScreen({required this.fileName, required this.fetcher});

  final String fileName;
  final Future<Uint8List> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(fileName),
      ),
      body: Center(
        child: InteractiveViewer(
          child: AuthenticatedImage(fetcher: fetcher, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
            hasFilters ? Icons.search_off : Icons.report_problem_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'Nema prijava kvarova za zadane filtere.'
                : 'Nema prijava kvarova.',
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
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
