import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_city.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route.dart';
import 'package:aquaflow_desktop/admin/models/admin_reading_route_item.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_item_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_item_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_reading_route_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_service.dart';
import 'package:aquaflow_desktop/admin/widgets/reading_route_status_pill.dart';

/// Pushed as its own `Scaffold`+`AppBar` route (same pattern as
/// `CustomerRequestsScreen`) to manage the water meters on one reading
/// route: add a meter individually (search-as-you-type by serial number),
/// bulk-add every meter in a settlement, remove a meter, and reorder the
/// list.
class AdminReadingRouteItemsScreen extends StatefulWidget {
  const AdminReadingRouteItemsScreen({super.key, required this.route});

  final AdminReadingRoute route;

  @override
  State<AdminReadingRouteItemsScreen> createState() =>
      _AdminReadingRouteItemsScreenState();
}

class _AdminReadingRouteItemsScreenState
    extends State<AdminReadingRouteItemsScreen> {
  final AdminReadingRouteService _routeService = AdminReadingRouteService();
  final AdminReadingRouteItemService _itemService =
      AdminReadingRouteItemService();
  final AdminWaterMeterService _waterMeterService = AdminWaterMeterService();
  final AdminCityService _cityService = AdminCityService();
  final AdminMunicipalityService _municipalityService =
      AdminMunicipalityService();
  final AdminSettlementService _settlementService = AdminSettlementService();

  List<AdminReadingRouteItem> _items = const [];
  List<AdminCity> _cities = const [];
  List<AdminMunicipality> _municipalities = const [];
  List<AdminSettlement> _settlements = const [];
  bool _loading = true;
  bool _mutating = false;
  bool _locationLookupsLoading = false;
  String? _error;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestSerial;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _routeService.fetchItems(widget.route.id);
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on AdminReadingRouteException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = e.message;
      });
    }
  }

  /// Best-effort load of the Grad/Općina/Naselje lookups for the "Dodaj po
  /// naselju" dialog - same lazy-fetch-once pattern as `AdminUsersScreen`.
  Future<void> _ensureLocationLookupsLoaded() async {
    if (_cities.isNotEmpty && _municipalities.isNotEmpty) return;
    if (_locationLookupsLoading) return;

    setState(() => _locationLookupsLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _cityService.fetchAll(),
        _municipalityService.fetchAll(),
        _settlementService.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _cities = results[0] as List<AdminCity>;
        _municipalities = results[1] as List<AdminMunicipality>;
        _settlements = results[2] as List<AdminSettlement>;
      });
    } on AdminCityException catch (e) {
      if (mounted) _showError(e.message);
    } on AdminMunicipalityException catch (e) {
      if (mounted) _showError(e.message);
    } on AdminSettlementException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _locationLookupsLoading = false);
    }
  }

  Future<void> _openAddSingle() async {
    final meter = await showDialog<AdminWaterMeter>(
      context: context,
      builder: (_) => _AddWaterMeterDialog(service: _waterMeterService),
    );
    if (!mounted || meter == null) return;

    final nextSortOrder = _items.isEmpty
        ? 1
        : _items.map((item) => item.sortOrder).reduce(
              (a, b) => a > b ? a : b,
            ) +
            1;

    await _runMutation(() async {
      await _itemService.addItem(widget.route.id, meter.id, nextSortOrder);
    }, 'Vodomjer je dodan na rutu.');
  }

  Future<void> _openAddBySettlement() async {
    await _ensureLocationLookupsLoaded();
    if (!mounted) return;

    final settlementId = await showDialog<int>(
      context: context,
      builder: (_) => _AddBySettlementDialog(
        cities: _cities,
        municipalities: _municipalities,
        settlements: _settlements,
      ),
    );
    if (!mounted || settlementId == null) return;

    await _runMutation(() async {
      await _routeService.bulkAddBySettlement(widget.route.id, settlementId);
    }, 'Vodomjeri iz naselja su dodani na rutu.');
  }

  Future<void> _confirmRemove(AdminReadingRouteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ukloni vodomjer'),
        content: Text(
          'Da li želite ukloniti vodomjer "${item.waterMeterSerialNumber}" sa rute?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Ukloni'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(() async {
      await _itemService.removeItem(item.id);
    }, 'Vodomjer je uklonjen sa rute.');
  }

  Future<void> _moveUp(int index) => _swap(index, index - 1);

  Future<void> _moveDown(int index) => _swap(index, index + 1);

  Future<void> _swap(int indexA, int indexB) async {
    if (indexA < 0 ||
        indexB < 0 ||
        indexA >= _items.length ||
        indexB >= _items.length) {
      return;
    }
    final a = _items[indexA];
    final b = _items[indexB];

    await _runMutation(() async {
      await _itemService.reorder(a.id, b.sortOrder);
      await _itemService.reorder(b.id, a.sortOrder);
    }, 'Redoslijed je sačuvan.');
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
    } on AdminReadingRouteItemException catch (e) {
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
    _routeService.dispose();
    _itemService.dispose();
    _waterMeterService.dispose();
    _cityService.dispose();
    _municipalityService.dispose();
    _settlementService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
        actions: [
          IconButton(
            tooltip: 'Dodaj vodomjer',
            onPressed: _mutating ? null : _openAddSingle,
            icon: const Icon(Icons.add),
          ),
          TextButton.icon(
            onPressed: _mutating ? null : _openAddBySettlement,
            icon: const Icon(Icons.holiday_village_outlined),
            label: const Text('Dodaj po naselju'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RouteHeader(route: widget.route),
          if (_mutating) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 40),
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
                      DataColumn(label: Text('Serijski broj')),
                      DataColumn(label: Text('Korisnik')),
                      DataColumn(label: Text('Naselje')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (var i = 0; i < _items.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text(_items[i].waterMeterSerialNumber)),
                            DataCell(
                              Text(
                                _items[i].customerFullName.isEmpty
                                    ? '-'
                                    : _items[i].customerFullName,
                              ),
                            ),
                            DataCell(
                              Text(
                                _items[i].settlementName.isEmpty
                                    ? '-'
                                    : _items[i].settlementName,
                              ),
                            ),
                            DataCell(Text(_items[i].status)),
                            DataCell(
                              _ItemRowActions(
                                disabled: _mutating,
                                canMoveUp: i > 0,
                                canMoveDown: i < _items.length - 1,
                                onMoveUp: () => _moveUp(i),
                                onMoveDown: () => _moveDown(i),
                                onRemove: () => _confirmRemove(_items[i]),
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
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.route});

  final AdminReadingRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _HeaderFact(icon: Icons.event_outlined, label: _formatDate(route.scheduledDate)),
          ReadingRouteStatusPill(status: route.status),
          _HeaderFact(
            icon: Icons.assignment_ind_outlined,
            label: route.collectorFullName,
            muted: route.collectorId == null,
          ),
        ],
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  const _HeaderFact({required this.icon, required this.label, this.muted = false});

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontStyle: muted ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class _ItemRowActions extends StatelessWidget {
  const _ItemRowActions({
    required this.disabled,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final bool disabled;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Pomjeri gore',
          onPressed: disabled || !canMoveUp ? null : onMoveUp,
          icon: const Icon(Icons.arrow_upward, size: 18),
        ),
        IconButton(
          tooltip: 'Pomjeri dolje',
          onPressed: disabled || !canMoveDown ? null : onMoveDown,
          icon: const Icon(Icons.arrow_downward, size: 18),
        ),
        IconButton(
          tooltip: 'Ukloni',
          onPressed: disabled ? null : onRemove,
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

/// Search-as-you-type picker for adding a single water meter to the route,
/// filtering `GET /WaterMeters?SerialNumber=` via `AdminWaterMeterService`.
class _AddWaterMeterDialog extends StatefulWidget {
  const _AddWaterMeterDialog({required this.service});

  final AdminWaterMeterService service;

  @override
  State<_AddWaterMeterDialog> createState() => _AddWaterMeterDialogState();
}

class _AddWaterMeterDialogState extends State<_AddWaterMeterDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _debounce;
  List<AdminWaterMeter> _results = const [];
  bool _loading = false;
  String? _error;
  int _requestSerial = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _queueSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final requestId = ++_requestSerial;
    setState(() => _loading = true);
    try {
      final results = await widget.service.search(serialNumber: query);
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } on AdminWaterMeterException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj vodomjer'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _queueSearch,
              decoration: const InputDecoration(
                labelText: 'Serijski broj',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: _buildResults(),
            ),
          ],
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

  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _searchCtrl.text.trim().isEmpty
              ? 'Unesite serijski broj za pretragu.'
              : 'Nema rezultata.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final meter = _results[index];
        return ListTile(
          title: Text(meter.serialNumber),
          subtitle: Text(meter.settlementName.isEmpty ? '-' : meter.settlementName),
          onTap: () => Navigator.of(context).pop(meter),
        );
      },
    );
  }
}

/// Cascading Grad -> Općina -> Naselje picker, same pattern as the address
/// step of `AdminUsersScreen`'s editor dialog, used to bulk-add every water
/// meter in a settlement via `AdminReadingRouteService.bulkAddBySettlement`.
class _AddBySettlementDialog extends StatefulWidget {
  const _AddBySettlementDialog({
    required this.cities,
    required this.municipalities,
    required this.settlements,
  });

  final List<AdminCity> cities;
  final List<AdminMunicipality> municipalities;
  final List<AdminSettlement> settlements;

  @override
  State<_AddBySettlementDialog> createState() =>
      _AddBySettlementDialogState();
}

class _AddBySettlementDialogState extends State<_AddBySettlementDialog> {
  int? _cityId;
  int? _municipalityId;
  int? _settlementId;

  List<AdminMunicipality> get _municipalitiesForSelectedCity =>
      widget.municipalities
          .where((municipality) => municipality.cityId == _cityId)
          .toList();

  List<AdminSettlement> get _settlementsForSelectedMunicipality => widget
      .settlements
      .where((settlement) => settlement.municipalityId == _municipalityId)
      .toList();

  void _onCityChanged(int? cityId) {
    setState(() {
      _cityId = cityId;
      if (_municipalityId != null &&
          !_municipalitiesForSelectedCity.any((m) => m.id == _municipalityId)) {
        _municipalityId = null;
        _settlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _municipalityId = municipalityId;
      if (_settlementId != null &&
          !_settlementsForSelectedMunicipality.any((s) => s.id == _settlementId)) {
        _settlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _settlementId = settlementId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj po naselju'),
      content: SizedBox(
        width: 420,
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
                const DropdownMenuItem(value: 0, child: Text('Odaberite grad')),
                for (final city in widget.cities)
                  DropdownMenuItem(value: city.id, child: Text(city.name)),
              ],
              onChanged: (value) => _onCityChanged(value == 0 ? null : value),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _municipalityId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Općina',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Odaberite općinu')),
                for (final municipality in _municipalitiesForSelectedCity)
                  DropdownMenuItem(
                    value: municipality.id,
                    child: Text(municipality.name),
                  ),
              ],
              onChanged: _cityId == null
                  ? null
                  : (value) => _onMunicipalityChanged(value == 0 ? null : value),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _settlementId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Naselje',
                prefixIcon: Icon(Icons.holiday_village_outlined),
              ),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Odaberite naselje')),
                for (final settlement in _settlementsForSelectedMunicipality)
                  DropdownMenuItem(
                    value: settlement.id,
                    child: Text(settlement.name),
                  ),
              ],
              onChanged: _municipalityId == null
                  ? null
                  : (value) => _onSettlementChanged(value == 0 ? null : value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _settlementId == null
              ? null
              : () => Navigator.of(context).pop(_settlementId),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Ruta još nema dodanih vodomjera.',
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
