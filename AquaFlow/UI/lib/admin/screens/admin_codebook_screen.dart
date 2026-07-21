import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_city.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                color: isLast
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      } else {
        children.add(
          Tooltip(
            message: 'Otvori',
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
// Shared chrome (empty state, delete confirm) - identical across all three
// levels, so it is defined once for the whole file. The header/pagination
// bar/error state now come from lib/shared/widgets/ instead of a local copy;
// the empty state stays local because it supports an optional "create" action
// button on the true-empty state (Općine/Naselja), which the generic shared
// EmptyStateView doesn't.
// ---------------------------------------------------------------------------

class _CodebookEmptyState extends StatelessWidget {
  const _CodebookEmptyState({
    required this.icon,
    required this.hasFilters,
    required this.emptyMessage,
    required this.filteredMessage,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final bool hasFilters;
  final String emptyMessage;
  final String filteredMessage;

  /// Shown only for the true-empty state (never while a search is active,
  /// since "Očisti pretragu" already covers that case).
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAction = !hasFilters && actionLabel != null && onAction != null;

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
          if (showAction) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
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

/// True when the just-deleted row was the only one left on a page other than
/// the first, so the view should step back a page instead of showing an
/// empty page. Shared by all three levels so the behaviour stays consistent.
bool shouldStepBackAfterDelete({required int itemsOnPage, required int page}) {
  return itemsOnPage == 1 && page > 1;
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

class _CitiesViewState extends State<_CitiesView>
    with PagedListController<AdminCity, _CitiesView> {
  final AdminCityService _service = AdminCityService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminCity> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      name: searchController.text,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminCityException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  Future<void> _openCreate() async {
    final draft = await showDialog<_CityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CityEditorDialog(),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
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

    await runMutation(() async {
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

    await runMutation(() async {
      await _service.delete(city.id);
      if (shouldStepBackAfterDelete(itemsOnPage: items.length, page: page)) {
        page -= 1;
      }
    }, 'Grad je obrisan.');
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Gradovi',
                subtitle: 'Pregled, dodavanje, uređivanje i brisanje gradova.',
                actions: [
                  IconButton(
                    tooltip: 'Osvježi',
                    onPressed: loading || mutating ? null : () => load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: loading || mutating ? null : _openCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Novi grad'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFilters(),
            ],
          ),
        ),
        if ((loading && !isInitialLoad) || mutating)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent()),
        if (!isInitialLoad && error == null)
          PagedTablePaginationBar(
            page: page,
            totalPages: totalPages,
            totalCount: totalCount,
            pageSize: pageSize,
            loading: loading || mutating,
            onPageChanged: goToPage,
            onPageSizeChanged: setPageSize,
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final hasSearch = searchController.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onChanged: queueSearch,
        onSubmitted: submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv grada',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasSearch
              ? IconButton(
                  tooltip: 'Očisti pretragu',
                  onPressed: clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
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
                                  TableRowActions(
                                    disabled: mutating,
                                    onEdit: () => _openEdit(item),
                                    onDelete: () => _confirmAndDelete(item),
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

  bool get _hasFilters => searchController.text.trim().isNotEmpty;
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

class _MunicipalitiesViewState extends State<_MunicipalitiesView>
    with PagedListController<AdminMunicipality, _MunicipalitiesView> {
  final AdminMunicipalityService _service = AdminMunicipalityService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminMunicipality> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      name: searchController.text,
      cityId: widget.city.id,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminMunicipalityException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  Future<void> _openCreate() async {
    final draft = await showDialog<_MunicipalityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MunicipalityEditorDialog(city: widget.city),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
      await _service.create(
        name: draft.name,
        code: draft.code,
        cityId: widget.city.id,
      );
    }, 'Općina je dodana.');
  }

  Future<void> _openEdit(AdminMunicipality municipality) async {
    final draft = await showDialog<_MunicipalityDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MunicipalityEditorDialog(
        city: widget.city,
        municipality: municipality,
      ),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
      await _service.update(
        municipality.id,
        name: draft.name,
        code: draft.code,
        cityId: widget.city.id,
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

    await runMutation(() async {
      await _service.delete(municipality.id);
      if (shouldStepBackAfterDelete(itemsOnPage: items.length, page: page)) {
        page -= 1;
      }
    }, 'Općina je obrisana.');
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Općine · ${widget.city.name}',
                subtitle: 'Pregled, dodavanje, uređivanje i brisanje općina.',
                actions: [
                  IconButton(
                    tooltip: 'Osvježi',
                    onPressed: loading || mutating ? null : () => load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: loading || mutating ? null : _openCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova općina'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFilters(),
            ],
          ),
        ),
        if ((loading && !isInitialLoad) || mutating)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent()),
        if (!isInitialLoad && error == null)
          PagedTablePaginationBar(
            page: page,
            totalPages: totalPages,
            totalCount: totalCount,
            pageSize: pageSize,
            loading: loading || mutating,
            onPageChanged: goToPage,
            onPageSizeChanged: setPageSize,
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final hasSearch = searchController.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onChanged: queueSearch,
        onSubmitted: submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv općine',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasSearch
              ? IconButton(
                  tooltip: 'Očisti pretragu',
                  onPressed: clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
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
      return _CodebookEmptyState(
        icon: Icons.map_outlined,
        hasFilters: _hasFilters,
        emptyMessage: "Grad '${widget.city.name}' još nema općina.",
        filteredMessage: 'Nema općina za zadanu pretragu.',
        actionLabel: 'Nova općina',
        onAction: _openCreate,
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
                                  TableRowActions(
                                    disabled: mutating,
                                    onEdit: () => _openEdit(item),
                                    onDelete: () => _confirmAndDelete(item),
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

  bool get _hasFilters => searchController.text.trim().isNotEmpty;
}

class _MunicipalityDraft {
  const _MunicipalityDraft({required this.name, required this.code});

  final String name;
  final String code;
}

class _MunicipalityEditorDialog extends StatefulWidget {
  const _MunicipalityEditorDialog({required this.city, this.municipality});

  final AdminCity city;
  final AdminMunicipality? municipality;

  @override
  State<_MunicipalityEditorDialog> createState() =>
      _MunicipalityEditorDialogState();
}

class _MunicipalityEditorDialogState extends State<_MunicipalityEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool get _isEdit => widget.municipality != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.municipality?.name ?? '';
    _codeCtrl.text = widget.municipality?.code ?? '';
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
      _MunicipalityDraft(name: _nameCtrl.text.trim(), code: _codeCtrl.text.trim()),
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
                TextFormField(
                  initialValue: widget.city.name,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Grad',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
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

class _SettlementsViewState extends State<_SettlementsView>
    with PagedListController<AdminSettlement, _SettlementsView> {
  final AdminSettlementService _service = AdminSettlementService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminSettlement> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      name: searchController.text,
      municipalityId: widget.municipality.id,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminSettlementException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  Future<void> _openCreate() async {
    final draft = await showDialog<_SettlementDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SettlementEditorDialog(municipality: widget.municipality),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
      await _service.create(
        name: draft.name,
        municipalityId: widget.municipality.id,
        postalCode: draft.postalCode,
      );
    }, 'Naselje je dodano.');
  }

  Future<void> _openEdit(AdminSettlement settlement) async {
    final draft = await showDialog<_SettlementDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SettlementEditorDialog(
        municipality: widget.municipality,
        settlement: settlement,
      ),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
      await _service.update(
        settlement.id,
        name: draft.name,
        municipalityId: widget.municipality.id,
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

    await runMutation(() async {
      await _service.delete(settlement.id);
      if (shouldStepBackAfterDelete(itemsOnPage: items.length, page: page)) {
        page -= 1;
      }
    }, 'Naselje je obrisano.');
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Naselja · ${widget.municipality.name}',
                subtitle: 'Pregled, dodavanje, uređivanje i brisanje naselja.',
                actions: [
                  IconButton(
                    tooltip: 'Osvježi',
                    onPressed: loading || mutating ? null : () => load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: loading || mutating ? null : _openCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo naselje'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFilters(),
            ],
          ),
        ),
        if ((loading && !isInitialLoad) || mutating)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent()),
        if (!isInitialLoad && error == null)
          PagedTablePaginationBar(
            page: page,
            totalPages: totalPages,
            totalCount: totalCount,
            pageSize: pageSize,
            loading: loading || mutating,
            onPageChanged: goToPage,
            onPageSizeChanged: setPageSize,
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final hasSearch = searchController.text.trim().isNotEmpty;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onChanged: queueSearch,
        onSubmitted: submitSearch,
        decoration: InputDecoration(
          labelText: 'Pretraga',
          hintText: 'Naziv naselja',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasSearch
              ? IconButton(
                  tooltip: 'Očisti pretragu',
                  onPressed: clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
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
      return _CodebookEmptyState(
        icon: Icons.holiday_village_outlined,
        hasFilters: _hasFilters,
        emptyMessage: "Općina '${widget.municipality.name}' još nema naselja.",
        filteredMessage: 'Nema naselja za zadanu pretragu.',
        actionLabel: 'Novo naselje',
        onAction: _openCreate,
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
                              TableRowActions(
                                disabled: mutating,
                                onEdit: () => _openEdit(item),
                                onDelete: () => _confirmAndDelete(item),
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

  bool get _hasFilters => searchController.text.trim().isNotEmpty;
}

class _SettlementDraft {
  const _SettlementDraft({required this.name, required this.postalCode});

  final String name;
  final String postalCode;
}

class _SettlementEditorDialog extends StatefulWidget {
  const _SettlementEditorDialog({required this.municipality, this.settlement});

  final AdminMunicipality municipality;
  final AdminSettlement? settlement;

  @override
  State<_SettlementEditorDialog> createState() =>
      _SettlementEditorDialogState();
}

class _SettlementEditorDialogState extends State<_SettlementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  bool get _isEdit => widget.settlement != null;

  @override
  void initState() {
    super.initState();
    final settlement = widget.settlement;
    _nameCtrl.text = settlement?.name ?? '';
    _postalCodeCtrl.text = settlement?.postalCode ?? '';
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
                TextFormField(
                  initialValue: widget.municipality.name,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Općina',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
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
