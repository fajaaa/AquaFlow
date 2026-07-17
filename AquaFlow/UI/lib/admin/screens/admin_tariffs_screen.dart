import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/admin/models/admin_tariff.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_tariff_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_tariff_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_tariff_service.dart';
import 'package:aquaflow_desktop/shared/utils/money_format.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminTariffsScreen extends StatefulWidget {
  const AdminTariffsScreen({super.key});

  @override
  State<AdminTariffsScreen> createState() => _AdminTariffsScreenState();
}

class _AdminTariffsScreenState extends State<AdminTariffsScreen> {
  final AdminTariffService _service = AdminTariffService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminTariffPage? _pageData;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  bool? _isActiveFilter;
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
        isActive: _isActiveFilter,
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
                ScreenHeader(
                  title: 'Tarife',
                  subtitle: 'Pregled, dodavanje, uređivanje i brisanje tarifa.',
                  actions: [
                    IconButton(
                      tooltip: 'Osvježi',
                      onPressed: _loading || _mutating ? null : () => _load(),
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _loading || _mutating ? null : _openCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Nova tarifa'),
                    ),
                  ],
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
            PagedTablePaginationBar(
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
      return ErrorRetry(message: error, onRetry: () => _load());
    }

    final items = _pageData?.items ?? const <AdminTariff>[];
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.request_quote_outlined,
        message: 'Nema tarifa.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema tarifa za zadane filtere.',
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
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
                    columns: const [
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Opis')),
                      DataColumn(label: Text('Cijena po m³')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(Text(item.name)),
                            DataCell(
                              Tooltip(
                                message: item.description,
                                child: SizedBox(
                                  width: 240,
                                  child: Text(
                                    item.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text('${formatMoney(item.pricePerM3)} KM/m³')),
                            DataCell(_TariffStatusPill(tariff: item)),
                            DataCell(
                              TableRowActions(
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
      _searchCtrl.text.trim().isNotEmpty || _isActiveFilter != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _TariffStatusPill extends StatelessWidget {
  const _TariffStatusPill({required this.tariff});

  final AdminTariff tariff;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = !tariff.isActive
        ? ('Neaktivna', const Color(0xFF64748B), Icons.block_outlined)
        : ('Aktivna', const Color(0xFF2E7D32), Icons.check_circle_outline);

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
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  late bool _isActive;

  bool get _isEdit => widget.tariff != null;

  @override
  void initState() {
    super.initState();
    final tariff = widget.tariff;
    _nameCtrl.text = tariff?.name ?? '';
    _descriptionCtrl.text = tariff?.description ?? '';
    _priceCtrl.text = tariff != null ? formatMoney(tariff.pricePerM3) : '';
    _isActive = tariff?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    final formValid = form != null && form.validate();
    if (!formValid) return;

    Navigator.of(context).pop(
      AdminTariffDraft(
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        pricePerM3: parseDecimal(_priceCtrl.text) ?? 0,
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
                  controller: _descriptionCtrl,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  maxLength: 200,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceCtrl,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _decimalValidator,
                  decoration: const InputDecoration(
                    labelText: 'Cijena po m³',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
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
    final parsed = parseDecimal(value ?? '');
    if (parsed == null) return 'Unesite ispravan broj.';
    if (parsed < 0) return 'Vrijednost ne smije biti negativna.';
    return null;
  }
}

