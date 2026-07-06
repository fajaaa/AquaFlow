import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter_request.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter_request_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_request_service.dart';

class AdminWaterMeterRequestsScreen extends StatefulWidget {
  const AdminWaterMeterRequestsScreen({super.key});

  @override
  State<AdminWaterMeterRequestsScreen> createState() =>
      _AdminWaterMeterRequestsScreenState();
}

class _AdminWaterMeterRequestsScreenState
    extends State<AdminWaterMeterRequestsScreen> {
  final AdminWaterMeterRequestService _service =
      AdminWaterMeterRequestService();

  AdminWaterMeterRequestPage? _pageData;
  List<AdminCollectorProfile> _collectors = const [];
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
        status: _statusFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminWaterMeterRequestException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<bool> _loadCollectors() async {
    try {
      final collectors = await _service.fetchCollectors();
      if (!mounted) return false;
      setState(() => _collectors = collectors);
      return true;
    } on AdminWaterMeterRequestException catch (e) {
      if (!mounted) return false;
      _showError(e.message);
      return false;
    }
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

  Future<void> _openAssign(AdminWaterMeterRequest request) async {
    final loaded = await _loadCollectors();
    if (!mounted || !loaded) return;

    if (_collectors.isEmpty) {
      _showError('Nema dostupnih inkasanata.');
      return;
    }

    final collectorId = await showDialog<int>(
      context: context,
      builder: (_) => _AssignDialog(collectors: _collectors),
    );
    if (!mounted || collectorId == null) return;

    await _runMutation(() async {
      await _service.assign(request.id, collectorId);
    }, 'Zahtjev je dodijeljen inkasantu.');
  }

  Future<void> _openReject(AdminWaterMeterRequest request) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (!mounted || reason == null) return;

    await _runMutation(() async {
      await _service.reject(request.id, reason);
    }, 'Zahtjev je odbijen.');
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
    } on AdminWaterMeterRequestException catch (e) {
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Svi statusi')),
              DropdownMenuItem(value: 'Pending', child: Text('Na čekanju')),
              DropdownMenuItem(
                value: 'Assigned',
                child: Text('Čeka registraciju'),
              ),
              DropdownMenuItem(value: 'Registered', child: Text('Registrovan')),
              DropdownMenuItem(value: 'Rejected', child: Text('Odbijen')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Otkazan')),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filter',
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

    final items = _pageData?.items ?? const <AdminWaterMeterRequest>[];
    if (items.isEmpty) {
      return _EmptyState(hasFilter: _statusFilter != null);
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
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 88,
                    columns: const [
                      DataColumn(label: Text('Zahtjev')),
                      DataColumn(label: Text('Korisnik')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Collector')),
                      DataColumn(label: Text('Kreiran')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(_RequestCell(request: item)),
                            DataCell(Text('#${item.customerId}')),
                            DataCell(_RequestStatusPill(status: item.status)),
                            DataCell(
                              Text(_collectorLabel(item.assignedCollectorId)),
                            ),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _RowActions(
                                request: item,
                                disabled: _mutating,
                                onAssign: () => _openAssign(item),
                                onReject: () => _openReject(item),
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

  String _collectorLabel(int? collectorId) {
    if (collectorId == null) return '-';
    for (final collector in _collectors) {
      if (collector.id == collectorId) return collector.label;
    }
    return 'Collector #$collectorId';
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
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
          'Zahtjevi za vodomjer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled, dodjela collectoru i odbijanje zahtjeva za novi vodomjer.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(child: title),
        IconButton(
          tooltip: 'Osvježi',
          onPressed: loading || mutating ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _RequestCell extends StatelessWidget {
  const _RequestCell({required this.request});

  final AdminWaterMeterRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = request.serviceLocationAddress.trim().isEmpty
        ? 'Lokacija #${request.serviceLocationId}'
        : request.serviceLocationAddress.trim();
    final note = request.note?.trim();

    return SizedBox(
      width: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note == null || note.isEmpty ? 'Zahtjev #${request.id}' : note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.request,
    required this.disabled,
    required this.onAssign,
    required this.onReject,
  });

  final AdminWaterMeterRequest request;
  final bool disabled;
  final VoidCallback onAssign;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    if (!request.isPending) {
      final text = request.isAssigned ? 'Čeka registraciju' : '-';
      return Text(text);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Dodijeli inkasantu',
          onPressed: disabled ? null : onAssign,
          icon: const Icon(Icons.assignment_ind_outlined),
        ),
        IconButton(
          tooltip: 'Odbij',
          onPressed: disabled ? null : onReject,
          icon: const Icon(Icons.block_outlined),
        ),
      ],
    );
  }
}

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.collectors});

  final List<AdminCollectorProfile> collectors;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  int? _collectorId;

  @override
  void initState() {
    super.initState();
    _collectorId = widget.collectors.length == 1
        ? widget.collectors.first.id
        : null;
  }

  void _selectCollector(AdminCollectorProfile collector) {
    setState(() => _collectorId = collector.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Dodijeli inkasantu'),
      content: SizedBox(
        width: 820,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 44,
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 66,
                      columns: const [
                        DataColumn(label: Text('Izbor')),
                        DataColumn(label: Text('Ime i prezime')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Telefon')),
                        DataColumn(label: Text('Područje')),
                      ],
                      rows: [
                        for (final collector in widget.collectors)
                          _buildCollectorRow(context, collector),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _collectorId == null
              ? null
              : () => Navigator.of(context).pop(_collectorId),
          icon: const Icon(Icons.assignment_ind_outlined),
          label: const Text('Dodijeli'),
        ),
      ],
    );
  }

  DataRow _buildCollectorRow(
    BuildContext context,
    AdminCollectorProfile collector,
  ) {
    final theme = Theme.of(context);
    final selected = collector.id == _collectorId;
    final iconColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return DataRow(
      selected: selected,
      onSelectChanged: (_) => _selectCollector(collector),
      cells: [
        DataCell(
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: iconColor,
            size: 20,
          ),
        ),
        DataCell(
          SizedBox(
            width: 230,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profileLabel(collector),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              _textOrDash(collector.email),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              _textOrDash(collector.phone),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(collector.areaLabel)),
      ],
    );
  }

  String _profileLabel(AdminCollectorProfile collector) {
    final code = collector.employeeCode.trim();
    if (code.isNotEmpty) return code;
    return 'Profil #${collector.id}';
  }

  String _textOrDash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbij zahtjev'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _reasonCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Razlog (opciono)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_outlined),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_reasonCtrl.text),
          icon: const Icon(Icons.block_outlined),
          label: const Text('Odbij'),
        ),
      ],
    );
  }
}

class _RequestStatusPill extends StatelessWidget {
  const _RequestStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'pending' => (
        'Na čekanju',
        const Color(0xFFB45309),
        Icons.hourglass_top_outlined,
      ),
      'assigned' => (
        'Čeka registraciju',
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'registered' => (
        'Registrovan',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      'rejected' => ('Odbijen', const Color(0xFFB91C1C), Icons.block_outlined),
      'cancelled' => (
        'Otkazan',
        const Color(0xFF64748B),
        Icons.cancel_outlined,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Row(
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
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.assignment_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilter
                ? 'Nema zahtjeva za odabrani status.'
                : 'Nema zahtjeva za novi vodomjer.',
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
