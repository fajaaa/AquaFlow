import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_option.dart';
import 'package:aquaflow_desktop/admin/services/admin_service_location_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_service_location_service.dart';

/// Desktop CRUD table over `/ServiceLocations`, following the `AdminUsersScreen`
/// template. When [customerId] is set (the "Lokacije" row action on the
/// customers tab of `AdminUsersScreen` opens it this way), every listing call
/// is pinned to that customer's locations and the create dialog preselects
/// them - editing an existing row still shows its own real customer, though,
/// since a location can be reassigned to a different customer.
///
/// [settlementId] works the same way for a settlement (opened from the
/// "Lokacije" row action on the settlements screen): every listing call is
/// pinned to that settlement, the settlement filter and column are hidden, and
/// the create dialog preselects it - editing an existing row still keeps its
/// own real settlement.
class AdminServiceLocationsScreen extends StatefulWidget {
  const AdminServiceLocationsScreen({
    super.key,
    this.customerId,
    this.settlementId,
    this.settlementName,
  });

  final int? customerId;
  final int? settlementId;
  final String? settlementName;

  @override
  State<AdminServiceLocationsScreen> createState() =>
      _AdminServiceLocationsScreenState();
}

class _AdminServiceLocationsScreenState
    extends State<AdminServiceLocationsScreen> {
  final AdminServiceLocationService _service = AdminServiceLocationService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminServiceLocationPage? _pageData;
  List<AdminCustomerProfile> _customers = const [];
  List<AdminSettlementOption> _settlements = const [];
  bool _loading = true;
  bool _mutating = false;
  bool _lookupsLoading = false;
  String? _error;
  int? _settlementFilterId;
  String? _typeFilter;
  bool? _activeFilter;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLookups(showErrors: false);
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
        customerId: widget.customerId,
        settlementId: widget.settlementId ?? _settlementFilterId,
        locationType: _typeFilter,
        isActive: _activeFilter,
        address: _searchCtrl.text,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminServiceLocationException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<bool> _loadLookups({bool showErrors = true}) async {
    if (_lookupsLoading) return false;

    setState(() => _lookupsLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchCustomers(),
        _service.fetchSettlements(),
      ]);
      if (!mounted) return false;
      setState(() {
        _customers = results[0] as List<AdminCustomerProfile>;
        _settlements = results[1] as List<AdminSettlementOption>;
      });
      return true;
    } on AdminServiceLocationException catch (e) {
      if (!mounted) return false;
      if (showErrors) _showError(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _lookupsLoading = false);
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

  void _setSettlementFilter(int value) {
    final selected = value == 0 ? null : value;
    if (selected == _settlementFilterId) return;
    setState(() => _settlementFilterId = selected);
    _load(resetPage: true);
  }

  void _setTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _typeFilter) return;
    setState(() => _typeFilter = selected);
    _load(resetPage: true);
  }

  void _setActiveFilter(String value) {
    final selected = value == 'active'
        ? true
        : (value == 'inactive' ? false : null);
    if (selected == _activeFilter) return;
    setState(() => _activeFilter = selected);
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
    final loaded = _customers.isNotEmpty && _settlements.isNotEmpty
        ? true
        : await _loadLookups();
    if (!mounted || !loaded) return;

    final draft = await showDialog<AdminServiceLocationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationEditorDialog(
        customers: _customers,
        settlements: _settlements,
        pinnedCustomerId: widget.customerId,
        pinnedSettlementId: widget.settlementId,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(draft);
    }, 'Lokacija je dodana.');
  }

  Future<void> _openEdit(AdminServiceLocation location) async {
    final loaded = _customers.isNotEmpty && _settlements.isNotEmpty
        ? true
        : await _loadLookups();
    if (!mounted || !loaded) return;

    final draft = await showDialog<AdminServiceLocationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationEditorDialog(
        customers: _customers,
        settlements: _settlements,
        pinnedCustomerId: widget.customerId,
        pinnedSettlementId: widget.settlementId,
        location: location,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(location.id, draft);
    }, 'Lokacija je sačuvana.');
  }

  Future<void> _toggleActive(AdminServiceLocation location) async {
    final nextActive = !location.isActive;
    await _runMutation(() async {
      await _service.setActive(location.id, nextActive);
    }, nextActive ? 'Lokacija je aktivirana.' : 'Lokacija je deaktivirana.');
  }

  Future<void> _confirmDelete(AdminServiceLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši lokaciju'),
        content: Text(
          'Da li želite obrisati lokaciju "${location.address}"? '
          'Ova radnja se ne može poništiti.',
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
      await _service.delete(location.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Lokacija je obrisana.');
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
    } on AdminServiceLocationException catch (e) {
      if (!mounted) return;
      // e.message already carries the backend's { message, errors } text
      // (e.g. the FK reference list on delete, or a 400 validation error).
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

  /// Resolved from the loaded customer list once available; falls back to a
  /// generic label until then (or if the id isn't found on the page loaded).
  String? get _pinnedCustomerLabel {
    final pinnedId = widget.customerId;
    if (pinnedId == null) return null;
    for (final customer in _customers) {
      if (customer.id == pinnedId) return customer.label;
    }
    return 'Kupac #$pinnedId';
  }

  /// Label for the pinned settlement, taken from the name passed in by the
  /// caller and falling back to a generic id label.
  String? get _pinnedSettlementLabel {
    final pinnedId = widget.settlementId;
    if (pinnedId == null) return null;
    final name = widget.settlementName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Naselje #$pinnedId';
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
                  pinnedCustomerLabel: _pinnedCustomerLabel,
                  settlementLabel: _pinnedSettlementLabel,
                  loading: _loading || _lookupsLoading,
                  mutating: _mutating,
                  onRefresh: () {
                    _load();
                    _loadLookups();
                  },
                  onCreate: _openCreate,
                ),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if ((_loading && pageData != null) || _mutating || _lookupsLoading)
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
    final activeValue = _activeFilter == null
        ? ''
        : (_activeFilter! ? 'active' : 'inactive');

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
              labelText: 'Pretraga',
              hintText: 'Adresa',
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
        // The settlement is fixed when the screen is pinned to one, so the
        // "Naselje" filter would be redundant - hide it in that mode.
        if (widget.settlementId == null)
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int>(
              initialValue: _settlementFilterId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Naselje',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Sva naselja')),
                for (final settlement in _settlements)
                  DropdownMenuItem(
                    value: settlement.id,
                    child: Text(settlement.label),
                  ),
              ],
              onChanged: _loading || _mutating
                  ? null
                  : (value) => _setSettlementFilter(value ?? 0),
            ),
          ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: _typeFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Tip lokacije',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Svi tipovi')),
              DropdownMenuItem(value: 'Residential', child: Text('Stambeni')),
              DropdownMenuItem(value: 'Commercial', child: Text('Poslovni')),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setTypeFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: activeValue,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.toggle_on_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Sve')),
              DropdownMenuItem(value: 'active', child: Text('Aktivne')),
              DropdownMenuItem(value: 'inactive', child: Text('Neaktivne')),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setActiveFilter(value ?? ''),
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

    final items = _pageData?.items ?? const <AdminServiceLocation>[];
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
                    columns: [
                      const DataColumn(label: Text('Adresa')),
                      // Redundant when every row is the same pinned settlement.
                      if (widget.settlementId == null)
                        const DataColumn(label: Text('Naselje')),
                      const DataColumn(label: Text('Kupac')),
                      const DataColumn(label: Text('Tip')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items) _buildRow(context, item),
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

  DataRow _buildRow(BuildContext context, AdminServiceLocation location) {
    final theme = Theme.of(context);
    final dimmed = !location.isActive;
    final textStyle = dimmed
        ? theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          )
        : theme.textTheme.bodyMedium;

    return DataRow(
      onSelectChanged: (_) => _openEdit(location),
      cells: [
        DataCell(Text(_textOrDash(location.address), style: textStyle)),
        if (widget.settlementId == null)
          DataCell(
            Text(_textOrDash(location.settlementName), style: textStyle),
          ),
        DataCell(Text(_textOrDash(location.customerName), style: textStyle)),
        DataCell(Text(_typeLabel(location.locationType), style: textStyle)),
        DataCell(_StatusPill(isActive: location.isActive)),
        DataCell(
          _RowActions(
            location: location,
            disabled: _mutating,
            onEdit: () => _openEdit(location),
            onToggleActive: () => _toggleActive(location),
            onDelete: () => _confirmDelete(location),
          ),
        ),
      ],
    );
  }

  bool get _hasFilters =>
      _searchCtrl.text.trim().isNotEmpty ||
      _settlementFilterId != null ||
      _typeFilter != null ||
      _activeFilter != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pinnedCustomerLabel,
    required this.settlementLabel,
    required this.loading,
    required this.mutating,
    required this.onRefresh,
    required this.onCreate,
  });

  final String? pinnedCustomerLabel;
  final String? settlementLabel;
  final bool loading;
  final bool mutating;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinnedCustomer = pinnedCustomerLabel;
    final pinnedSettlement = settlementLabel;

    final String subtitle;
    if (pinnedCustomer != null) {
      subtitle = 'Lokacije kupca: $pinnedCustomer';
    } else if (pinnedSettlement != null) {
      subtitle = 'Lokacije u naselju: $pinnedSettlement';
    } else {
      subtitle =
          'Pregled, dodavanje, uređivanje i deaktivacija servisnih lokacija.';
    }

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokacije',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
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
          label: const Text('Nova lokacija'),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B);
    final label = isActive ? 'Aktivna' : 'Neaktivna';
    final icon = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

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

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.location,
    required this.disabled,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AdminServiceLocation location;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = location.isActive;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: disabled ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: isActive ? 'Deaktiviraj' : 'Aktiviraj',
          onPressed: disabled ? null : onToggleActive,
          icon: Icon(
            isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
          ),
          color: isActive ? const Color(0xFF2E7D32) : null,
        ),
        PopupMenuButton<String>(
          tooltip: 'Više opcija',
          enabled: !disabled,
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text('Obriši'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationEditorDialog extends StatefulWidget {
  const _LocationEditorDialog({
    required this.customers,
    required this.settlements,
    this.pinnedCustomerId,
    this.pinnedSettlementId,
    this.location,
  });

  final List<AdminCustomerProfile> customers;
  final List<AdminSettlementOption> settlements;

  /// Preselects the customer dropdown when creating a new location from the
  /// "Lokacije" row action on a specific customer; ignored when [location] is
  /// set (editing keeps that location's own customer as the initial value).
  final int? pinnedCustomerId;

  /// Preselects the settlement dropdown when creating a new location from the
  /// "Lokacije" row action on a specific settlement; ignored when [location] is
  /// set (editing keeps that location's own settlement as the initial value).
  final int? pinnedSettlementId;
  final AdminServiceLocation? location;

  @override
  State<_LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<_LocationEditorDialog> {
  static const Map<String, String> _typeLabels = {
    'Residential': 'Stambeni',
    'Commercial': 'Poslovni',
  };

  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();

  int? _customerId;
  int? _settlementId;
  late String _locationType;
  late bool _isActive;

  bool get _isEdit => widget.location != null;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _customerId = location?.customerId ?? widget.pinnedCustomerId;
    _settlementId = location?.settlementId ?? widget.pinnedSettlementId;
    _locationType = (location?.locationType.isNotEmpty ?? false)
        ? location!.locationType
        : 'Residential';
    _isActive = location?.isActive ?? true;
    _addressCtrl.text = location?.address ?? '';
    _latitudeCtrl.text = location?.latitude == null
        ? ''
        : _formatNumber(location!.latitude!);
    _longitudeCtrl.text = location?.longitude == null
        ? ''
        : _formatNumber(location!.longitude!);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      AdminServiceLocationDraft(
        customerId: _customerId!,
        settlementId: _settlementId!,
        address: _addressCtrl.text.trim(),
        locationType: _locationType,
        latitude: _parseOptionalDouble(_latitudeCtrl.text),
        longitude: _parseOptionalDouble(_longitudeCtrl.text),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi lokaciju' : 'Nova lokacija'),
      content: SizedBox(
        width: math.min(520, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _customerId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Kupac',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _customerItems(),
                  validator: (value) =>
                      value == null || value == 0 ? 'Obavezno polje.' : null,
                  onChanged: (value) {
                    setState(() => _customerId = value == 0 ? null : value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _settlementId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Naselje',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: _settlementItems(),
                  validator: (value) =>
                      value == null || value == 0 ? 'Obavezno polje.' : null,
                  onChanged: (value) {
                    setState(() => _settlementId = value == 0 ? null : value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Adresa',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _locationType,
                  decoration: const InputDecoration(
                    labelText: 'Tip lokacije',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _typeItems(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _locationType = value);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: _latitudeValidator,
                        decoration: const InputDecoration(
                          labelText: 'Latitude (opciono)',
                          prefixIcon: Icon(Icons.explore_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: _longitudeValidator,
                        decoration: const InputDecoration(
                          labelText: 'Longitude (opciono)',
                          prefixIcon: Icon(Icons.explore_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StatusSwitchField(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
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

  List<DropdownMenuItem<int>> _customerItems() {
    final ids = widget.customers.map((c) => c.id).toSet();
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('Odaberite kupca')),
      for (final customer in widget.customers)
        DropdownMenuItem(value: customer.id, child: Text(customer.label)),
    ];

    final currentId = _customerId;
    if (currentId != null && currentId != 0 && !ids.contains(currentId)) {
      items.insert(
        1,
        DropdownMenuItem(value: currentId, child: Text('Kupac #$currentId')),
      );
    }
    return items;
  }

  List<DropdownMenuItem<int>> _settlementItems() {
    final ids = widget.settlements.map((s) => s.id).toSet();
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('Odaberite naselje')),
      for (final settlement in widget.settlements)
        DropdownMenuItem(value: settlement.id, child: Text(settlement.label)),
    ];

    final currentId = _settlementId;
    if (currentId != null && currentId != 0 && !ids.contains(currentId)) {
      items.insert(
        1,
        DropdownMenuItem(
          value: currentId,
          child: Text('Naselje #$currentId'),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<String>> _typeItems() {
    final items = [
      for (final entry in _typeLabels.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ];
    if (!_typeLabels.containsKey(_locationType)) {
      items.insert(
        0,
        DropdownMenuItem(value: _locationType, child: Text(_locationType)),
      );
    }
    return items;
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
  }

  String? _latitudeValidator(String? value) =>
      _coordinateValidator(value, -90, 90);

  String? _longitudeValidator(String? value) =>
      _coordinateValidator(value, -180, 180);

  String? _coordinateValidator(String? value, double min, double max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Unesite ispravan broj.';
    if (parsed < min || parsed > max) {
      return 'Vrijednost mora biti između $min i $max.';
    }
    return null;
  }

  double? _parseOptionalDouble(String value) {
    final text = value.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  String _formatNumber(double value) {
    final text = value.toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

class _StatusSwitchField extends StatelessWidget {
  const _StatusSwitchField({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6ED)),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: value ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ? 'Aktivna' : 'Neaktivna',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
            hasFilters ? Icons.search_off : Icons.location_on_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'Nema lokacija za zadane filtere.'
                : 'Nema evidentiranih lokacija.',
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

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}

String _typeLabel(String value) {
  switch (value) {
    case 'Residential':
      return 'Stambeni';
    case 'Commercial':
      return 'Poslovni';
    default:
      return _textOrDash(value);
  }
}
