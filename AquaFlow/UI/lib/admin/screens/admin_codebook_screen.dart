import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_city.dart';
import 'package:aquaflow_desktop/admin/models/admin_city_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_service.dart';

/// Administrative location codebook: Grad -> Općina -> Naselje. A single
/// drill-in shell - Gradovi, then the municipalities of a selected city, then
/// the settlements of a selected municipality - with a breadcrumb + back
/// button for navigating back up. Each level is a self-contained CRUD view
/// built on the same shared chrome (search, paging, create/edit dialog,
/// delete confirm with backend-message-passthrough exceptions).
class AdminCodebookScreen extends StatefulWidget {
  const AdminCodebookScreen({super.key});

  @override
  State<AdminCodebookScreen> createState() => _AdminCodebookScreenState();
}

enum _CodebookLevel { cities, municipalities, settlements }

class _AdminCodebookScreenState extends State<AdminCodebookScreen> {
  _CodebookLevel _level = _CodebookLevel.cities;
  AdminCity? _selectedCity;
  AdminMunicipality? _selectedMunicipality;

  void _openCity(AdminCity city) {
    setState(() {
      _selectedCity = city;
      _selectedMunicipality = null;
      _level = _CodebookLevel.municipalities;
    });
  }

  void _openMunicipality(AdminMunicipality municipality) {
    setState(() {
      _selectedMunicipality = municipality;
      _level = _CodebookLevel.settlements;
    });
  }

  void _goToCities() {
    setState(() {
      _level = _CodebookLevel.cities;
      _selectedCity = null;
      _selectedMunicipality = null;
    });
  }

  void _goToMunicipalities() {
    setState(() {
      _level = _CodebookLevel.municipalities;
      _selectedMunicipality = null;
    });
  }

  void _goBack() {
    switch (_level) {
      case _CodebookLevel.cities:
        break;
      case _CodebookLevel.municipalities:
        _goToCities();
        break;
      case _CodebookLevel.settlements:
        _goToMunicipalities();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Šifarnik',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administrativni šifarnik lokacija: gradovi, općine i naselja.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 28, 8),
            child: Row(
              children: [
                if (_level != _CodebookLevel.cities)
                  IconButton(
                    tooltip: 'Nazad',
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox(width: 8),
                Expanded(child: _buildBreadcrumb(theme)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(ThemeData theme) {
    final items = <_BreadcrumbItem>[
      _BreadcrumbItem(
        'Gradovi',
        _level == _CodebookLevel.cities ? null : _goToCities,
      ),
    ];

    final city = _selectedCity;
    if (city != null) {
      items.add(
        _BreadcrumbItem(
          city.name,
          _level == _CodebookLevel.settlements ? _goToMunicipalities : null,
        ),
      );
    }

    final municipality = _selectedMunicipality;
    if (_level == _CodebookLevel.settlements && municipality != null) {
      items.add(_BreadcrumbItem(municipality.name, null));
    }

    return _Breadcrumb(items: items);
  }

  Widget _buildBody() {
    switch (_level) {
      case _CodebookLevel.cities:
        return _CitiesView(
          key: const ValueKey('codebook-cities'),
          onOpenCity: _openCity,
        );
      case _CodebookLevel.municipalities:
        final city = _selectedCity!;
        return _MunicipalitiesView(
          key: ValueKey('codebook-municipalities-${city.id}'),
          city: city,
          onOpenMunicipality: _openMunicipality,
        );
      case _CodebookLevel.settlements:
        final municipality = _selectedMunicipality!;
        return _SettlementsView(
          key: ValueKey('codebook-settlements-${municipality.id}'),
          municipality: municipality,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb
// ---------------------------------------------------------------------------

class _BreadcrumbItem {
  const _BreadcrumbItem(this.label, this.onTap);

  final String label;
  final VoidCallback? onTap;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.items});

  final List<_BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      if (item.onTap == null) {
        children.add(
          Text(
            item.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
              color: isLast
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      } else {
        children.add(
          InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                item.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}

// ---------------------------------------------------------------------------
// Shared chrome (header, pagination, empty/error states, delete confirm) -
// identical across all three levels, so it is defined once for the whole
// file.
// ---------------------------------------------------------------------------

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.title,
    required this.subtitle,
    required this.createLabel,
    required this.loading,
    required this.mutating,
    required this.onRefresh,
    required this.onCreate,
  });

  final String title;
  final String subtitle;
  final String createLabel;
  final bool loading;
  final bool mutating;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          label: Text(createLabel),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          children: [Expanded(child: text), actions],
        );
      },
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

class _CodebookEmptyState extends StatelessWidget {
  const _CodebookEmptyState({
    required this.icon,
    required this.hasFilters,
    required this.emptyMessage,
    required this.filteredMessage,
  });

  final IconData icon;
  final bool hasFilters;
  final String emptyMessage;
  final String filteredMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.search_off : icon,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? filteredMessage : emptyMessage,
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

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
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
          icon: const Icon(Icons.delete_outline),
          label: const Text('Obriši'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}

String? _requiredValidator(String? value) {
  return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
}

// ---------------------------------------------------------------------------
// Gradovi
// ---------------------------------------------------------------------------

class _CitiesView extends StatefulWidget {
  const _CitiesView({super.key, required this.onOpenCity});

  final ValueChanged<AdminCity> onOpenCity;

  @override
  State<_CitiesView> createState() => _CitiesViewState();
}

class _CitiesViewState extends State<_CitiesView> {
  final AdminCityService _service = AdminCityService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminCityPage? _pageData;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
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
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminCityException catch (e) {
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
    final draft = await showDialog<_CityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CityEditorDialog(),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(name: draft.name, code: draft.code);
    }, 'Grad je dodan.');
  }

  Future<void> _openEdit(AdminCity city) async {
    final draft = await showDialog<_CityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CityEditorDialog(city: city),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(city.id, name: draft.name, code: draft.code);
    }, 'Grad je sačuvan.');
  }

  Future<void> _confirmAndDelete(AdminCity city) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Obriši grad',
      message:
          'Da li želite obrisati grad "${city.name}"? '
          'Ova radnja se ne može poništiti.',
    );
    if (!mounted || !confirmed) return;

    await _runMutation(() async {
      await _service.delete(city.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Grad je obrisan.');
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
    } on AdminCityException catch (e) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(
                title: 'Gradovi',
                subtitle: 'Pregled, dodavanje, uređivanje i brisanje gradova.',
                createLabel: 'Novi grad',
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
    );
  }

  Widget _buildFilters() {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: _queueSearch,
        onSubmitted: _submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv grada',
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

    final items = _pageData?.items ?? const <AdminCity>[];
    if (items.isEmpty) {
      return _CodebookEmptyState(
        icon: Icons.location_city_outlined,
        hasFilters: _hasFilters,
        emptyMessage: 'Nema gradova.',
        filteredMessage: 'Nema gradova za zadanu pretragu.',
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
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Kod')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => widget.onOpenCity(item),
                          cells: [
                            DataCell(Text(_textOrDash(item.name))),
                            DataCell(Text(_textOrDash(item.code))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Uredi',
                                    onPressed: _mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Obriši',
                                    onPressed: _mutating
                                        ? null
                                        : () => _confirmAndDelete(item),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
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

  bool get _hasFilters => _searchCtrl.text.trim().isNotEmpty;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _CityDraft {
  const _CityDraft({required this.name, required this.code});

  final String name;
  final String code;
}

class _CityEditorDialog extends StatefulWidget {
  const _CityEditorDialog({this.city});

  final AdminCity? city;

  @override
  State<_CityEditorDialog> createState() => _CityEditorDialogState();
}

class _CityEditorDialogState extends State<_CityEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool get _isEdit => widget.city != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.city?.name ?? '';
    _codeCtrl.text = widget.city?.code ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _CityDraft(name: _nameCtrl.text.trim(), code: _codeCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi grad' : 'Novi grad'),
      content: SizedBox(
        width: math.min(420, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeCtrl,
                  textInputAction: TextInputAction.done,
                  validator: _requiredValidator,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Kod',
                    prefixIcon: Icon(Icons.tag_outlined),
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
}

// ---------------------------------------------------------------------------
// Općine
// ---------------------------------------------------------------------------

class _MunicipalitiesView extends StatefulWidget {
  const _MunicipalitiesView({
    super.key,
    required this.city,
    required this.onOpenMunicipality,
  });

  final AdminCity city;
  final ValueChanged<AdminMunicipality> onOpenMunicipality;

  @override
  State<_MunicipalitiesView> createState() => _MunicipalitiesViewState();
}

class _MunicipalitiesViewState extends State<_MunicipalitiesView> {
  final AdminMunicipalityService _service = AdminMunicipalityService();
  final AdminCityService _cityService = AdminCityService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminMunicipalityPage? _pageData;
  List<AdminCity> _cities = const [];
  bool _loading = true;
  bool _mutating = false;
  bool _citiesLoading = false;
  String? _error;
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
        cityId: widget.city.id,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminMunicipalityException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<bool> _loadCities({bool showErrors = true}) async {
    if (_citiesLoading) return false;

    setState(() => _citiesLoading = true);
    try {
      final cities = await _cityService.fetchAll();
      if (!mounted) return false;
      setState(() => _cities = cities);
      return true;
    } on AdminCityException catch (e) {
      if (!mounted) return false;
      if (showErrors) _showError(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _citiesLoading = false);
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
    final loaded = _cities.isNotEmpty || await _loadCities();
    if (!mounted || !loaded) return;
    if (_cities.isEmpty) {
      _showError('Prvo dodajte barem jedan grad.');
      return;
    }

    final draft = await showDialog<_MunicipalityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MunicipalityEditorDialog(
        cities: _cities,
        initialCityId: widget.city.id,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(
        name: draft.name,
        code: draft.code,
        cityId: draft.cityId,
      );
    }, 'Općina je dodana.');
  }

  Future<void> _openEdit(AdminMunicipality municipality) async {
    final loaded = _cities.isNotEmpty || await _loadCities();
    if (!mounted || !loaded) return;

    final draft = await showDialog<_MunicipalityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _MunicipalityEditorDialog(cities: _cities, municipality: municipality),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(
        municipality.id,
        name: draft.name,
        code: draft.code,
        cityId: draft.cityId,
      );
    }, 'Općina je sačuvana.');
  }

  Future<void> _confirmAndDelete(AdminMunicipality municipality) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Obriši općinu',
      message:
          'Da li želite obrisati općinu "${municipality.name}"? '
          'Ova radnja se ne može poništiti.',
    );
    if (!mounted || !confirmed) return;

    await _runMutation(() async {
      await _service.delete(municipality.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Općina je obrisana.');
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
    } on AdminMunicipalityException catch (e) {
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
    _cityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(
                title: 'Općine',
                subtitle: 'Općine grada "${widget.city.name}".',
                createLabel: 'Nova općina',
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
    );
  }

  Widget _buildFilters() {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: _queueSearch,
        onSubmitted: _submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv općine',
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

    final items = _pageData?.items ?? const <AdminMunicipality>[];
    if (items.isEmpty) {
      return _CodebookEmptyState(
        icon: Icons.map_outlined,
        hasFilters: _hasFilters,
        emptyMessage: 'Nema općina za ovaj grad.',
        filteredMessage: 'Nema općina za zadanu pretragu.',
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
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Kod')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => widget.onOpenMunicipality(item),
                          cells: [
                            DataCell(Text(_textOrDash(item.name))),
                            DataCell(Text(_textOrDash(item.code))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Uredi',
                                    onPressed: _mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Obriši',
                                    onPressed: _mutating
                                        ? null
                                        : () => _confirmAndDelete(item),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
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

  bool get _hasFilters => _searchCtrl.text.trim().isNotEmpty;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _MunicipalityDraft {
  const _MunicipalityDraft({
    required this.name,
    required this.code,
    required this.cityId,
  });

  final String name;
  final String code;
  final int cityId;
}

class _MunicipalityEditorDialog extends StatefulWidget {
  const _MunicipalityEditorDialog({
    required this.cities,
    this.municipality,
    this.initialCityId,
  });

  final List<AdminCity> cities;
  final AdminMunicipality? municipality;
  final int? initialCityId;

  @override
  State<_MunicipalityEditorDialog> createState() =>
      _MunicipalityEditorDialogState();
}

class _MunicipalityEditorDialogState extends State<_MunicipalityEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  int? _cityId;

  bool get _isEdit => widget.municipality != null;

  @override
  void initState() {
    super.initState();
    final municipality = widget.municipality;
    _nameCtrl.text = municipality?.name ?? '';
    _codeCtrl.text = municipality?.code ?? '';

    final cityIds = widget.cities.map((city) => city.id).toSet();
    if (municipality != null && cityIds.contains(municipality.cityId)) {
      _cityId = municipality.cityId;
    } else if (widget.initialCityId != null &&
        cityIds.contains(widget.initialCityId)) {
      _cityId = widget.initialCityId;
    } else if (widget.cities.length == 1) {
      _cityId = widget.cities.first.id;
    } else {
      _cityId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _MunicipalityDraft(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        cityId: _cityId ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi općinu' : 'Nova općina'),
      content: SizedBox(
        width: math.min(460, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _cityId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Grad',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Odaberite grad'),
                    ),
                    for (final city in widget.cities)
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                  ],
                  validator: (value) =>
                      value == null || value == 0 ? 'Obavezno polje.' : null,
                  onChanged: (value) {
                    setState(() => _cityId = value == 0 ? null : value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeCtrl,
                  textInputAction: TextInputAction.done,
                  validator: _requiredValidator,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Kod',
                    prefixIcon: Icon(Icons.tag_outlined),
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
}

// ---------------------------------------------------------------------------
// Naselja
// ---------------------------------------------------------------------------

class _SettlementsView extends StatefulWidget {
  const _SettlementsView({super.key, required this.municipality});

  final AdminMunicipality municipality;

  @override
  State<_SettlementsView> createState() => _SettlementsViewState();
}

class _SettlementsViewState extends State<_SettlementsView> {
  final AdminSettlementService _service = AdminSettlementService();
  final AdminMunicipalityService _municipalityService =
      AdminMunicipalityService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminSettlementPage? _pageData;
  List<AdminMunicipality> _municipalities = const [];
  bool _loading = true;
  bool _mutating = false;
  bool _municipalitiesLoading = false;
  String? _error;
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
        municipalityId: widget.municipality.id,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminSettlementException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<bool> _loadMunicipalities({bool showErrors = true}) async {
    if (_municipalitiesLoading) return false;

    setState(() => _municipalitiesLoading = true);
    try {
      final municipalities = await _municipalityService.fetchAll();
      if (!mounted) return false;
      setState(() => _municipalities = municipalities);
      return true;
    } on AdminMunicipalityException catch (e) {
      if (!mounted) return false;
      if (showErrors) _showError(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _municipalitiesLoading = false);
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
    final loaded = _municipalities.isNotEmpty || await _loadMunicipalities();
    if (!mounted || !loaded) return;
    if (_municipalities.isEmpty) {
      _showError('Prvo dodajte barem jednu općinu.');
      return;
    }

    final draft = await showDialog<_SettlementDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SettlementEditorDialog(
        municipalities: _municipalities,
        initialMunicipalityId: widget.municipality.id,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(
        name: draft.name,
        municipalityId: draft.municipalityId,
        postalCode: draft.postalCode,
      );
    }, 'Naselje je dodano.');
  }

  Future<void> _openEdit(AdminSettlement settlement) async {
    final loaded = _municipalities.isNotEmpty || await _loadMunicipalities();
    if (!mounted || !loaded) return;

    final draft = await showDialog<_SettlementDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SettlementEditorDialog(
        municipalities: _municipalities,
        settlement: settlement,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(
        settlement.id,
        name: draft.name,
        municipalityId: draft.municipalityId,
        postalCode: draft.postalCode,
      );
    }, 'Naselje je sačuvano.');
  }

  Future<void> _confirmAndDelete(AdminSettlement settlement) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Obriši naselje',
      message:
          'Da li želite obrisati naselje "${settlement.name}"? '
          'Ova radnja se ne može poništiti.',
    );
    if (!mounted || !confirmed) return;

    await _runMutation(() async {
      await _service.delete(settlement.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Naselje je obrisano.');
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
    } on AdminSettlementException catch (e) {
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
    _municipalityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(
                title: 'Naselja',
                subtitle: 'Naselja općine "${widget.municipality.name}".',
                createLabel: 'Novo naselje',
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
    );
  }

  Widget _buildFilters() {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: _queueSearch,
        onSubmitted: _submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv naselja',
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

    final items = _pageData?.items ?? const <AdminSettlement>[];
    if (items.isEmpty) {
      return _CodebookEmptyState(
        icon: Icons.holiday_village_outlined,
        hasFilters: _hasFilters,
        emptyMessage: 'Nema naselja za ovu općinu.',
        filteredMessage: 'Nema naselja za zadanu pretragu.',
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
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('Naziv')),
                      DataColumn(label: Text('Poštanski broj')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(Text(_textOrDash(item.name))),
                            DataCell(Text(_textOrDash(item.postalCode))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Uredi',
                                    onPressed: _mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Obriši',
                                    onPressed: _mutating
                                        ? null
                                        : () => _confirmAndDelete(item),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ],
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

  bool get _hasFilters => _searchCtrl.text.trim().isNotEmpty;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _SettlementDraft {
  const _SettlementDraft({
    required this.name,
    required this.municipalityId,
    required this.postalCode,
  });

  final String name;
  final int municipalityId;
  final String postalCode;
}

class _SettlementEditorDialog extends StatefulWidget {
  const _SettlementEditorDialog({
    required this.municipalities,
    this.settlement,
    this.initialMunicipalityId,
  });

  final List<AdminMunicipality> municipalities;
  final AdminSettlement? settlement;
  final int? initialMunicipalityId;

  @override
  State<_SettlementEditorDialog> createState() =>
      _SettlementEditorDialogState();
}

class _SettlementEditorDialogState extends State<_SettlementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  int? _municipalityId;

  bool get _isEdit => widget.settlement != null;

  @override
  void initState() {
    super.initState();
    final settlement = widget.settlement;
    _nameCtrl.text = settlement?.name ?? '';
    _postalCodeCtrl.text = settlement?.postalCode ?? '';

    final municipalityIds = widget.municipalities.map((m) => m.id).toSet();
    if (settlement != null &&
        municipalityIds.contains(settlement.municipalityId)) {
      _municipalityId = settlement.municipalityId;
    } else if (widget.initialMunicipalityId != null &&
        municipalityIds.contains(widget.initialMunicipalityId)) {
      _municipalityId = widget.initialMunicipalityId;
    } else if (widget.municipalities.length == 1) {
      _municipalityId = widget.municipalities.first.id;
    } else {
      _municipalityId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _SettlementDraft(
        name: _nameCtrl.text.trim(),
        municipalityId: _municipalityId ?? 0,
        postalCode: _postalCodeCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Uredi naselje' : 'Novo naselje'),
      content: SizedBox(
        width: math.min(480, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _municipalityId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Općina',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Odaberite općinu'),
                    ),
                    for (final municipality in widget.municipalities)
                      DropdownMenuItem(
                        value: municipality.id,
                        child: Text(municipality.name),
                      ),
                  ],
                  validator: (value) =>
                      value == null || value == 0 ? 'Obavezno polje.' : null,
                  onChanged: (value) {
                    setState(() => _municipalityId = value == 0 ? null : value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.holiday_village_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _postalCodeCtrl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Poštanski broj',
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined),
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
}
