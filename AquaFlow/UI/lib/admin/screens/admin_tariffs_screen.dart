import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/admin/models/admin_tariff.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_tariff_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_tariff_service.dart';

class AdminTariffsScreen extends StatefulWidget {
  const AdminTariffsScreen({super.key});

  @override
  State<AdminTariffsScreen> createState() => _AdminTariffsScreenState();
}

class _AdminTariffsScreenState extends State<AdminTariffsScreen> {
  final AdminTariffService _service = AdminTariffService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customerTypeCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminTariffPage? _pageData;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  bool? _isActiveFilter;
  DateTime? _effectiveOnFilter;
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
        name: _searchCtrl.text,
        customerType: _customerTypeCtrl.text,
        isActive: _isActiveFilter,
        effectiveOn: _effectiveOnFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminTariffException catch (e) {
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

  void _applyCustomerTypeFilter(String _) {
    _load(resetPage: true);
  }

  void _clearCustomerTypeFilter() {
    if (_customerTypeCtrl.text.isEmpty) return;
    _customerTypeCtrl.clear();
    setState(() {});
    _load(resetPage: true);
  }

  void _setStatusFilter(String value) {
    bool? selected;
    if (value == 'active') selected = true;
    if (value == 'inactive') selected = false;
    if (selected == _isActiveFilter) return;
    setState(() => _isActiveFilter = selected);
    _load(resetPage: true);
  }

  String get _statusFilterValue {
    if (_isActiveFilter == null) return '';
    return _isActiveFilter! ? 'active' : 'inactive';
  }

  Future<void> _pickEffectiveOnFilter() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveOnFilter ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || date == null) return;
    setState(() => _effectiveOnFilter = DateTime(date.year, date.month, date.day));
    _load(resetPage: true);
  }

  void _clearEffectiveOnFilter() {
    if (_effectiveOnFilter == null) return;
    setState(() => _effectiveOnFilter = null);
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
    final draft = await showDialog<AdminTariffDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TariffEditorDialog(),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(draft);
    }, 'Tarifa je dodana.');
  }

  Future<void> _openEdit(AdminTariff tariff) async {
    final draft = await showDialog<AdminTariffDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TariffEditorDialog(tariff: tariff),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(tariff.id, draft);
    }, 'Tarifa je sačuvana.');
  }

  Future<void> _confirmDelete(AdminTariff tariff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši tarifu'),
        content: Text(
          'Da li želite obrisati tarifu "${tariff.name}"? '
          'Brisanje neće biti moguće ako je tarifa referencirana stavkama računa.',
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
      await _service.delete(tariff.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Tarifa je obrisana.');
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
    } on AdminTariffException catch (e) {
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
    _customerTypeCtrl.dispose();
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
    final hasCustomerType = _customerTypeCtrl.text.trim().isNotEmpty;

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
          width: 220,
          child: TextField(
            controller: _customerTypeCtrl,
            enabled: !_loading && !_mutating,
            textInputAction: TextInputAction.search,
            onSubmitted: _applyCustomerTypeFilter,
            decoration: InputDecoration(
              labelText: 'Tip korisnika',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: hasCustomerType
                  ? IconButton(
                      tooltip: 'Očisti filter',
                      onPressed: _clearCustomerTypeFilter,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilterValue,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Sve')),
              DropdownMenuItem(value: 'active', child: Text('Aktivne')),
              DropdownMenuItem(value: 'inactive', child: Text('Neaktivne')),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 220,
          child: InkWell(
            onTap: _loading || _mutating ? null : _pickEffectiveOnFilter,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Važi na dan',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: _effectiveOnFilter == null
                    ? null
                    : IconButton(
                        tooltip: 'Ukloni filter',
                        onPressed: _clearEffectiveOnFilter,
                        icon: const Icon(Icons.clear),
                      ),
              ),
              child: Text(
                _effectiveOnFilter == null
                    ? 'Bilo koji datum'
                    : _formatDateOnly(_effectiveOnFilter!),
              ),
            ),
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

    final items = _pageData?.items ?? const <AdminTariff>[];
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
                      DataColumn(label: Text('Tip korisnika')),
                      DataColumn(label: Text('Cijena po m³')),
                      DataColumn(label: Text('Fiksna naknada')),
                      DataColumn(label: Text('Važenje')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(Text(item.name)),
                            DataCell(Text(item.customerType)),
                            DataCell(Text('${_formatMoney(item.pricePerM3)} KM/m³')),
                            DataCell(Text('${_formatMoney(item.fixedFee)} KM')),
                            DataCell(Text(_formatValidity(item))),
                            DataCell(_TariffStatusPill(tariff: item)),
                            DataCell(
                              _RowActions(
                                disabled: _mutating,
                                onEdit: () => _openEdit(item),
                                onDelete: () => _confirmDelete(item),
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
      _customerTypeCtrl.text.trim().isNotEmpty ||
      _isActiveFilter != null ||
      _effectiveOnFilter != null;

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
          'Tarife',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled, dodavanje, uređivanje i brisanje tarifa.',
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
          label: const Text('Nova tarifa'),
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
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
  });

  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: disabled ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
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

class _TariffStatusPill extends StatelessWidget {
  const _TariffStatusPill({required this.tariff});

  final AdminTariff tariff;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (tariff) {
      _ when !tariff.isActive => (
        'Neaktivna',
        const Color(0xFF64748B),
        Icons.block_outlined,
      ),
      _ when tariff.isExpired => (
        'Istekla',
        const Color(0xFFB45309),
        Icons.event_busy_outlined,
      ),
      _ => ('Aktivna', const Color(0xFF2E7D32), Icons.check_circle_outline),
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

class _TariffEditorDialog extends StatefulWidget {
  const _TariffEditorDialog({this.tariff});

  final AdminTariff? tariff;

  @override
  State<_TariffEditorDialog> createState() => _TariffEditorDialogState();
}

class _TariffEditorDialogState extends State<_TariffEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _customerTypeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();

  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  String? _effectiveFromError;
  String? _effectiveToError;
  late bool _isActive;

  bool get _isEdit => widget.tariff != null;

  @override
  void initState() {
    super.initState();
    final tariff = widget.tariff;
    _nameCtrl.text = tariff?.name ?? '';
    _customerTypeCtrl.text = tariff?.customerType ?? '';
    _priceCtrl.text = tariff != null ? _formatMoney(tariff.pricePerM3) : '';
    _feeCtrl.text = tariff != null ? _formatMoney(tariff.fixedFee) : '';
    _effectiveFrom = tariff?.effectiveFrom;
    _effectiveTo = tariff?.effectiveTo;
    _isActive = tariff?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customerTypeCtrl.dispose();
    _priceCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEffectiveFrom() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || date == null) return;
    setState(() {
      _effectiveFrom = DateTime(date.year, date.month, date.day);
      _effectiveFromError = null;
      if (_effectiveTo != null && _effectiveTo!.isBefore(_effectiveFrom!)) {
        _effectiveToError = 'Datum "do" ne smije biti prije datuma "od".';
      }
    });
  }

  Future<void> _pickEffectiveTo() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveTo ?? _effectiveFrom ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || date == null) return;
    setState(() {
      _effectiveTo = DateTime(date.year, date.month, date.day);
      _effectiveToError = null;
    });
  }

  void _clearEffectiveTo() {
    setState(() {
      _effectiveTo = null;
      _effectiveToError = null;
    });
  }

  void _save() {
    final form = _formKey.currentState;
    final formValid = form != null && form.validate();

    String? fromError;
    String? toError;
    final from = _effectiveFrom;
    final to = _effectiveTo;
    if (from == null) {
      fromError = 'Obavezno polje.';
    } else if (to != null && to.isBefore(from)) {
      toError = 'Datum "do" ne smije biti prije datuma "od".';
    }

    setState(() {
      _effectiveFromError = fromError;
      _effectiveToError = toError;
    });

    if (!formValid || fromError != null || toError != null) return;

    Navigator.of(context).pop(
      AdminTariffDraft(
        name: _nameCtrl.text.trim(),
        customerType: _customerTypeCtrl.text.trim(),
        pricePerM3: _parseDecimal(_priceCtrl.text) ?? 0,
        fixedFee: _parseDecimal(_feeCtrl.text) ?? 0,
        effectiveFrom: from!,
        effectiveTo: to,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi tarifu' : 'Nova tarifa'),
      content: SizedBox(
        width: math.min(640, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.label_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customerTypeCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Tip korisnika',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        validator: _decimalValidator,
                        decoration: const InputDecoration(
                          labelText: 'Cijena po m³',
                          prefixIcon: Icon(Icons.water_drop_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _feeCtrl,
                        textInputAction: TextInputAction.done,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        validator: _decimalValidator,
                        decoration: const InputDecoration(
                          labelText: 'Fiksna naknada',
                          prefixIcon: Icon(Icons.request_quote_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Važi od',
                  value: _effectiveFrom,
                  errorText: _effectiveFromError,
                  onPick: _pickEffectiveFrom,
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Važi do',
                  value: _effectiveTo,
                  errorText: _effectiveToError,
                  onPick: _pickEffectiveTo,
                  onClear: _effectiveTo == null ? null : _clearEffectiveTo,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktivna'),
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

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
  }

  String? _decimalValidator(String? value) {
    final parsed = _parseDecimal(value ?? '');
    if (parsed == null) return 'Unesite ispravan broj.';
    if (parsed < 0) return 'Vrijednost ne smije biti negativna.';
    return null;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : const Color(0xFFDCE6ED),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value == null ? 'Nije postavljeno' : _formatDateOnly(value!),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Odaberi datum',
                onPressed: onPick,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Ukloni datum',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
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
            hasFilters ? Icons.search_off : Icons.request_quote_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? 'Nema tarifa za zadane filtere.' : 'Nema tarifa.',
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

double? _parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String _formatMoney(double value) {
  final text = value.toStringAsFixed(4);
  final dotIndex = text.indexOf('.');
  var end = text.length;
  while (end > dotIndex + 3 && text[end - 1] == '0') {
    end--;
  }
  return text.substring(0, end);
}

String _formatDateOnly(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}

String _formatValidity(AdminTariff tariff) {
  final from = tariff.effectiveFrom;
  if (from == null) return '-';
  final to = tariff.effectiveTo;
  final fromText = 'od ${_formatDateOnly(from)}';
  if (to == null) return fromText;
  return '$fromText do ${_formatDateOnly(to)}';
}
