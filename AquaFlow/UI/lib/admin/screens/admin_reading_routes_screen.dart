import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_page.dart';
import 'package:aquaflow_desktop/admin/screens/admin_reading_route_items_screen.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_service.dart';
import 'package:aquaflow_desktop/admin/widgets/reading_route_status_pill.dart';

/// Desktop CRUD table over `/ReadingRoutes`, same template as
/// `AdminTariffsScreen` (`_requestSerial`/debounce/`_runMutation`, filter
/// row, paging). Row click (not the action icons) drills into
/// [AdminReadingRouteItemsScreen] for that route.
class AdminReadingRoutesScreen extends StatefulWidget {
  const AdminReadingRoutesScreen({super.key});

  @override
  State<AdminReadingRoutesScreen> createState() =>
      _AdminReadingRoutesScreenState();
}

class _AdminReadingRoutesScreenState extends State<AdminReadingRoutesScreen> {
  final AdminReadingRouteService _service = AdminReadingRouteService();
  final AdminCollectorService _collectorService = AdminCollectorService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminReadingRoutePage? _pageData;
  List<AdminCollectorProfile> _collectors = const [];
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  String? _statusFilter;
  int? _collectorFilter;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCollectors();
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
        name: _searchCtrl.text,
        status: _statusFilter,
        collectorId: _collectorFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminReadingRouteException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _loadCollectors() async {
    try {
      final page = await _collectorService.fetchCollectors(
        page: 1,
        pageSize: 100,
      );
      if (!mounted) return;
      setState(() => _collectors = page.items);
    } on AdminCollectorException catch (e) {
      if (!mounted) return;
      _showError(e.message);
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

  void _setCollectorFilter(int? value) {
    if (value == _collectorFilter) return;
    setState(() => _collectorFilter = value);
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

  Future<void> _openCreate() async {
    final draft = await showDialog<AdminReadingRouteDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RouteEditorDialog(),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(draft);
    }, 'Ruta je dodana.');
  }

  Future<void> _openEdit(AdminReadingRoute route) async {
    final draft = await showDialog<AdminReadingRouteDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RouteEditorDialog(route: route),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(route.id, draft);
    }, 'Ruta je sačuvana.');
  }

  Future<void> _confirmDelete(AdminReadingRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rutu'),
        content: Text(
          'Da li želite obrisati rutu "${route.name}"? '
          'Brisanje neće biti moguće ako ruta ima dodijeljene vodomjere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Obriši'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(() async {
      await _service.delete(route.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Ruta je obrisana.');
  }

  Future<void> _openAssign(AdminReadingRoute route) async {
    if (_collectors.isEmpty) {
      await _loadCollectors();
      if (!mounted) return;
    }
    if (_collectors.isEmpty) {
      _showError('Nema dostupnih inkasanata.');
      return;
    }

    final collectorId = await showDialog<int>(
      context: context,
      builder: (_) => _AssignCollectorDialog(
        collectors: _collectors,
        currentCollectorId: route.collectorId,
      ),
    );
    if (!mounted || collectorId == null) return;

    await _runMutation(() async {
      await _service.assign(route.id, collectorId);
    }, 'Inkasant je dodijeljen ruti.');
  }

  Future<void> _confirmCancel(AdminReadingRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rutu'),
        content: Text('Da li želite otkazati rutu "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Otkaži rutu'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(() async {
      await _service.cancel(route.id);
    }, 'Ruta je otkazana.');
  }

  void _openItems(AdminReadingRoute route) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => AdminReadingRouteItemsScreen(route: route),
          ),
        )
        .then((_) => _load());
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
    } on AdminReadingRouteException catch (e) {
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
    _collectorService.dispose();
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
                  onCreate: _openCreate,
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
          width: 240,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _queueSearch,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Naziv',
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
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Sve')),
              DropdownMenuItem(value: 'Planned', child: Text('Planned')),
              DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            initialValue: _collectorFilter ?? 0,
            decoration: const InputDecoration(
              labelText: 'Inkasant',
              prefixIcon: Icon(Icons.assignment_ind_outlined),
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Svi inkasanti')),
              for (final collector in _collectors)
                DropdownMenuItem(value: collector.id, child: Text(collector.label)),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setCollectorFilter(value == 0 ? null : value),
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

    final items = _pageData?.items ?? const <AdminReadingRoute>[];
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
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Datum')),
                      DataColumn(label: Text('Inkasant')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openItems(item),
                          cells: [
                            DataCell(Text(item.name)),
                            DataCell(Text(_formatDate(item.scheduledDate))),
                            DataCell(
                              Text(
                                item.collectorFullName,
                                style: item.collectorId == null
                                    ? TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      )
                                    : null,
                              ),
                            ),
                            DataCell(ReadingRouteStatusPill(status: item.status)),
                            DataCell(
                              _RowActions(
                                route: item,
                                disabled: _mutating,
                                onEdit: () => _openEdit(item),
                                onDelete: () => _confirmDelete(item),
                                onAssign: () => _openAssign(item),
                                onCancel: () => _confirmCancel(item),
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
      _searchCtrl.text.trim().isNotEmpty ||
      _statusFilter != null ||
      _collectorFilter != null;

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
    required this.onCreate,
  });

  final bool loading;
  final bool mutating;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rute',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled, dodavanje, uređivanje i dodjela ruta očitanja.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Osvježi',
          onPressed: loading || mutating ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: loading || mutating ? null : onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Nova ruta'),
        ),
      ],
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
    required this.route,
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
    required this.onCancel,
  });

  final AdminReadingRoute route;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isCancelled = route.status == 'Cancelled';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: disabled ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: route.collectorId == null
              ? 'Dodijeli inkasanta'
              : 'Promijeni inkasanta',
          onPressed: disabled || isCancelled ? null : onAssign,
          icon: const Icon(Icons.assignment_ind_outlined),
        ),
        IconButton(
          tooltip: 'Otkaži',
          onPressed: disabled || isCancelled ? null : onCancel,
          icon: const Icon(Icons.cancel_outlined),
          color: Theme.of(context).colorScheme.error,
        ),
        IconButton(
          tooltip: 'Obriši',
          onPressed: disabled ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _RouteEditorDialog extends StatefulWidget {
  const _RouteEditorDialog({this.route});

  final AdminReadingRoute? route;

  @override
  State<_RouteEditorDialog> createState() => _RouteEditorDialogState();
}

class _RouteEditorDialogState extends State<_RouteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  DateTime? _scheduledDate;

  bool get _isEdit => widget.route != null;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _nameCtrl.text = route?.name ?? '';
    _scheduledDate = route?.scheduledDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _scheduledDate = picked);
  }

  void _save() {
    final form = _formKey.currentState;
    final formValid = form != null && form.validate();
    final date = _scheduledDate;
    if (!formValid || date == null) return;

    Navigator.of(context).pop(
      AdminReadingRouteDraft(name: _nameCtrl.text.trim(), scheduledDate: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi rutu' : 'Nova ruta'),
      content: SizedBox(
        width: math.min(480, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.route_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(_formatDate(_scheduledDate)),
                  ),
                ),
              ],
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
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
  }
}

class _AssignCollectorDialog extends StatefulWidget {
  const _AssignCollectorDialog({
    required this.collectors,
    this.currentCollectorId,
  });

  final List<AdminCollectorProfile> collectors;
  final int? currentCollectorId;

  @override
  State<_AssignCollectorDialog> createState() =>
      _AssignCollectorDialogState();
}

class _AssignCollectorDialogState extends State<_AssignCollectorDialog> {
  int? _collectorId;

  @override
  void initState() {
    super.initState();
    final current = widget.currentCollectorId;
    _collectorId = current != null &&
            widget.collectors.any((collector) => collector.id == current)
        ? current
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodijeli inkasanta'),
      content: SizedBox(
        width: 380,
        child: DropdownButtonFormField<int>(
          initialValue: _collectorId,
          decoration: const InputDecoration(
            labelText: 'Inkasant',
            prefixIcon: Icon(Icons.assignment_ind_outlined),
          ),
          items: [
            for (final collector in widget.collectors)
              DropdownMenuItem(value: collector.id, child: Text(collector.label)),
          ],
          onChanged: (value) => setState(() => _collectorId = value),
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
            hasFilters ? Icons.search_off : Icons.route_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? 'Nema ruta za zadane filtere.' : 'Nema ruta.',
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
