import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/models/admin_city.dart';
import 'package:aquaflow_desktop/admin/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_municipality.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement.dart';
import 'package:aquaflow_desktop/admin/models/admin_user.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_user_role_option.dart';
import 'package:aquaflow_desktop/admin/screens/admin_user_water_meters_screen.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_city_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_municipality_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_settlement_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_user_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_user_service.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';

/// Which role this screen manages. The listing is pinned server-side to that
/// role and the editor dialog creates users with it, so "Korisnici" manages
/// customers and "Administratori" manages admins (collectors have their own
/// screen over /CollectorProfiles).
enum AdminUsersScreenMode {
  customers(
    roleName: 'Customer',
    title: 'Korisnici',
    subtitle: 'Pregled, dodavanje, uređivanje i brisanje korisničkih naloga.',
    singular: 'Korisnik',
    singularAccusative: 'korisnika',
    showWaterMeters: true,
  ),
  admins(
    roleName: 'Admin',
    title: 'Administratori',
    subtitle:
        'Pregled, dodavanje, uređivanje i brisanje administratorskih naloga.',
    singular: 'Administrator',
    singularAccusative: 'administratora',
    showWaterMeters: false,
  );

  const AdminUsersScreenMode({
    required this.roleName,
    required this.title,
    required this.subtitle,
    required this.singular,
    required this.singularAccusative,
    required this.showWaterMeters,
  });

  /// Backend `UserRole` name, sent as the `UserRole=` filter and used to
  /// resolve the role id for the editor dialog.
  final String roleName;
  final String title;
  final String subtitle;
  final String singular;
  final String singularAccusative;

  /// Customers have water meters; admins do not, so the action is hidden.
  final bool showWaterMeters;
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    this.mode = AdminUsersScreenMode.customers,
  });

  final AdminUsersScreenMode mode;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminUserService _service = AdminUserService();
  final AdminCityService _cityService = AdminCityService();
  final AdminMunicipalityService _municipalityService =
      AdminMunicipalityService();
  final AdminSettlementService _settlementService = AdminSettlementService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminUserPage? _pageData;
  List<AdminUserRoleOption> _roles = [];
  List<AdminCity> _cities = [];
  List<AdminMunicipality> _municipalities = [];
  List<AdminSettlement> _settlements = [];
  // Naselje per row (customers mode only) - CustomerProfile.SettlementName
  // isn't flattened onto UserResponse, so it's fetched per row after each
  // page load and cached here rather than requiring a backend change.
  Map<int, String> _settlementNameByUserId = {};
  bool _loading = true;
  bool _mutating = false;
  bool _locationLookupsLoading = false;
  String? _error;
  bool? _activeFilter;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _service.fetchRoles();
      if (!mounted) return;
      setState(() => _roles = roles);
    } on AdminUserException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  /// Best-effort load of the Grad/Općina/Naselje lookups used by the editor
  /// dialog's cascading address picker - address is optional, so a failure
  /// here should not block create/edit, just leave the dropdowns empty.
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
        userRole: widget.mode.roleName,
        isActive: _activeFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
      if (widget.mode == AdminUsersScreenMode.customers) {
        unawaited(_loadSettlementNames(requestId, pageData.items));
      }
    } on AdminUserException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  /// Fetches each row's CustomerProfile to populate the "Naselje" column.
  /// Runs in the background after the page renders, so a slow lookup doesn't
  /// delay the table itself; [requestId] guards against a stale response
  /// overwriting a newer page's data.
  Future<void> _loadSettlementNames(
    int requestId,
    List<AdminUser> items,
  ) async {
    final entries = await Future.wait(
      items.map((user) async {
        try {
          final profile = await _service.fetchCustomerProfile(user.id);
          return MapEntry(user.id, profile?.settlementName ?? '');
        } on AdminUserException {
          return MapEntry(user.id, '');
        }
      }),
    );
    if (!mounted || requestId != _requestSerial) return;
    setState(() => _settlementNameByUserId = Map.fromEntries(entries));
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

  int? get _currentUserId => context.read<AuthProvider>().session?.id;

  /// Resolves the id of the role this screen manages ([AdminUsersScreenMode]
  /// pins the whole screen to one role), or null with an error snackbar when
  /// the roles can't be loaded or the role name doesn't exist on the backend.
  Future<int?> _resolvePinnedRoleId() async {
    if (_roles.isEmpty) {
      await _loadRoles();
      if (!mounted) return null;
      if (_roles.isEmpty) {
        _showError('Uloge nisu učitane. Pokušajte ponovo.');
        return null;
      }
    }

    final roleName = widget.mode.roleName.toLowerCase();
    for (final role in _roles) {
      if (role.name.toLowerCase() == roleName) return role.id;
    }
    _showError('Rola "${widget.mode.roleName}" nije pronađena.');
    return null;
  }

  Future<void> _openCreate() async {
    final roleId = await _resolvePinnedRoleId();
    if (!mounted || roleId == null) return;
    await _ensureLocationLookupsLoaded();
    if (!mounted) return;

    final draft = await showDialog<AdminUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserEditorDialog(
        mode: widget.mode,
        userRoleId: roleId,
        cities: _cities,
        municipalities: _municipalities,
        settlements: _settlements,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(draft);
    }, '${widget.mode.singular} je dodan.');
  }

  Future<void> _openEdit(AdminUser user) async {
    final roleId = await _resolvePinnedRoleId();
    if (!mounted || roleId == null) return;
    await _ensureLocationLookupsLoaded();
    if (!mounted) return;

    AdminCustomerProfile? existingProfile;
    try {
      existingProfile = await _service.fetchCustomerProfile(user.id);
    } on AdminUserException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
    if (!mounted) return;

    final isSelf = user.id == _currentUserId;
    final draft = await showDialog<AdminUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserEditorDialog(
        mode: widget.mode,
        userRoleId: roleId,
        cities: _cities,
        municipalities: _municipalities,
        settlements: _settlements,
        user: user,
        disableDeactivate: isSelf,
        existingProfile: existingProfile,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(
        user.id,
        draft,
        existingProfileId: existingProfile?.id,
      );
    }, '${widget.mode.singular} je sačuvan.');
  }

  void _openWaterMeters(AdminUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserWaterMetersScreen(user: user),
      ),
    );
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Obriši ${widget.mode.singularAccusative}'),
        content: Text(
          'Da li želite obrisati ${widget.mode.singularAccusative} '
          '"${user.email}"? Ova radnja se ne može poništiti.',
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
      await _service.delete(user.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, '${widget.mode.singular} je obrisan.');
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
    } on AdminUserException catch (e) {
      if (!mounted) return;
      // e.message already carries the backend's error text (e.g. the FK
      // Restrict message when a user has related records), not a generic one.
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
    _municipalityService.dispose();
    _settlementService.dispose();
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
                  mode: widget.mode,
                  loading: _loading,
                  mutating: _mutating,
                  onRefresh: () {
                    _load();
                    _loadRoles();
                  },
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
    final activeValue = _activeFilter == null
        ? ''
        : (_activeFilter! ? 'active' : 'inactive');

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
              hintText: 'Ime ili prezime',
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
            initialValue: activeValue,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.toggle_on_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Svi')),
              DropdownMenuItem(value: 'active', child: Text('Aktivan')),
              DropdownMenuItem(value: 'inactive', child: Text('Neaktivan')),
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

    final items = _pageData?.items ?? const <AdminUser>[];
    if (items.isEmpty) {
      return _EmptyState(mode: widget.mode, hasFilters: _hasFilters);
    }

    final currentUserId = _currentUserId;

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
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 72,
                    columns: [
                      const DataColumn(label: Text('Ime i prezime')),
                      const DataColumn(label: Text('Email')),
                      const DataColumn(label: Text('Telefon')),
                      if (widget.mode == AdminUsersScreenMode.customers)
                        const DataColumn(label: Text('Naselje')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Kreiran')),
                      const DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(
                              Text(item.fullName.isEmpty ? '-' : item.fullName),
                            ),
                            DataCell(Text(item.email)),
                            DataCell(
                              Text(item.phone.isEmpty ? '-' : item.phone),
                            ),
                            if (widget.mode == AdminUsersScreenMode.customers)
                              DataCell(
                                Text(
                                  _textOrDash(
                                    _settlementNameByUserId[item.id] ?? '',
                                  ),
                                ),
                              ),
                            DataCell(_StatusPill(isActive: item.isActive)),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _RowActions(
                                disabled: _mutating,
                                deleteDisabled: item.id == currentUserId,
                                onEdit: () => _openEdit(item),
                                onDelete: () => _confirmDelete(item),
                                onWaterMeters: widget.mode.showWaterMeters
                                    ? () => _openWaterMeters(item)
                                    : null,
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
      _searchCtrl.text.trim().isNotEmpty || _activeFilter != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.loading,
    required this.mutating,
    required this.onRefresh,
    required this.onCreate,
  });

  final AdminUsersScreenMode mode;
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
          mode.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          mode.subtitle,
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
          label: Text('Novi ${mode.singular.toLowerCase()}'),
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
    final label = isActive ? 'Aktivan' : 'Neaktivan';
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
    required this.disabled,
    required this.deleteDisabled,
    required this.onEdit,
    required this.onDelete,
    this.onWaterMeters,
  });

  final bool disabled;
  final bool deleteDisabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Null hides the action entirely (admins have no water meters).
  final VoidCallback? onWaterMeters;

  @override
  Widget build(BuildContext context) {
    final deleteBlocked = disabled || deleteDisabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: disabled ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        if (onWaterMeters != null)
          IconButton(
            tooltip: 'Vodomjeri',
            onPressed: disabled ? null : onWaterMeters,
            icon: const Icon(Icons.water_drop_outlined),
          ),
        IconButton(
          tooltip: deleteDisabled
              ? 'Ne možete obrisati vlastiti korisnički nalog.'
              : 'Obriši',
          onPressed: deleteBlocked ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _UserEditorDialog extends StatefulWidget {
  const _UserEditorDialog({
    required this.mode,
    required this.userRoleId,
    required this.cities,
    required this.municipalities,
    required this.settlements,
    this.user,
    this.disableDeactivate = false,
    this.existingProfile,
  });

  final AdminUsersScreenMode mode;

  /// Id of the role this screen manages; the dialog offers no role choice, so
  /// every created/edited user keeps the screen's pinned role.
  final int userRoleId;
  final AdminUser? user;
  final bool disableDeactivate;
  final AdminCustomerProfile? existingProfile;

  /// Lookups for the cascading Grad -> Općina -> Naselje address picker.
  final List<AdminCity> cities;
  final List<AdminMunicipality> municipalities;
  final List<AdminSettlement> settlements;

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();

  late bool _isActive;
  late String _defaultLanguage;
  late String _theme;
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  bool get _isEdit => widget.user != null;

  // A profile is only submitted when the admin actually entered a name -
  // available for every role, not just Customer. For an edit of a user who
  // already has a profile, the name controllers are pre-filled from it (a
  // persisted profile always has a non-empty name), so this is already true
  // whenever an address-only change is made to an existing profile.
  bool get _hasProfileInput =>
      _firstNameCtrl.text.trim().isNotEmpty || _lastNameCtrl.text.trim().isNotEmpty;

  List<AdminMunicipality> get _municipalitiesForSelectedCity => widget
      .municipalities
      .where((municipality) => municipality.cityId == _selectedCityId)
      .toList();

  List<AdminSettlement> get _settlementsForSelectedMunicipality => widget
      .settlements
      .where((settlement) => settlement.municipalityId == _selectedMunicipalityId)
      .toList();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    final profile = widget.existingProfile;
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _isActive = user?.isActive ?? true;
    _firstNameCtrl.text = profile?.firstName ?? '';
    _lastNameCtrl.text = profile?.lastName ?? '';
    _defaultLanguage = profile?.defaultLanguage ?? 'bs';
    _theme = profile?.theme ?? 'light';
    _streetCtrl.text = profile?.street ?? '';
    _houseNumberCtrl.text = profile?.houseNumber ?? '';

    final settlementId = profile?.settlementId;
    if (settlementId != null) {
      final settlement = _findById(
        widget.settlements,
        settlementId,
        idOf: (s) => s.id,
      );
      if (settlement != null) {
        _selectedSettlementId = settlement.id;
        _selectedMunicipalityId = settlement.municipalityId;
        final municipality = _findById(
          widget.municipalities,
          settlement.municipalityId,
          idOf: (m) => m.id,
        );
        if (municipality != null) {
          _selectedCityId = municipality.cityId;
        }
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    super.dispose();
  }

  void _onCityChanged(int? cityId) {
    setState(() {
      _selectedCityId = cityId;
      if (_selectedMunicipalityId != null &&
          !_municipalitiesForSelectedCity.any(
            (m) => m.id == _selectedMunicipalityId,
          )) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality.any(
            (s) => s.id == _selectedSettlementId,
          )) {
        _selectedSettlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _selectedSettlementId = settlementId);
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final password = _passwordCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final houseNumber = _houseNumberCtrl.text.trim();

    Navigator.of(context).pop(
      AdminUserDraft(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        userRoleId: widget.userRoleId,
        isActive: _isActive,
        password: password.isEmpty ? null : password,
        profile: _hasProfileInput
            ? AdminCustomerProfileDraft(
                firstName: _firstNameCtrl.text.trim(),
                lastName: _lastNameCtrl.text.trim(),
                defaultLanguage: _defaultLanguage,
                theme: _theme,
                settlementId: _selectedSettlementId,
                street: street.isEmpty ? null : street,
                houseNumber: houseNumber.isEmpty ? null : houseNumber,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit
            ? 'Uredi ${widget.mode.singularAccusative}'
            : 'Novi ${widget.mode.singular.toLowerCase()}',
      ),
      content: SizedBox(
        width: math.min(520, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.existingProfile != null) ...[
                  TextFormField(
                    key: ValueKey(widget.existingProfile!.customerCode),
                    initialValue: widget.existingProfile!.customerCode,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Šifra korisnika (automatski dodijeljena)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _firstNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _firstNameValidator,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Ime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _lastNameValidator,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Prezime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _defaultLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Jezik',
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bs',
                            child: Text('Bosanski'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('Engleski'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _defaultLanguage = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _theme,
                        decoration: const InputDecoration(
                          labelText: 'Tema',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'light',
                            child: Text('Svijetla'),
                          ),
                          DropdownMenuItem(
                            value: 'dark',
                            child: Text('Tamna'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _theme = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCityId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Grad',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Bez grada')),
                    for (final city in widget.cities)
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                  ],
                  onChanged: (value) =>
                      _onCityChanged(value == 0 ? null : value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedMunicipalityId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Općina',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Bez općine'),
                    ),
                    for (final municipality in _municipalitiesForSelectedCity)
                      DropdownMenuItem(
                        value: municipality.id,
                        child: Text(municipality.name),
                      ),
                  ],
                  onChanged: _selectedCityId == null
                      ? null
                      : (value) =>
                            _onMunicipalityChanged(value == 0 ? null : value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedSettlementId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Naselje',
                    prefixIcon: Icon(Icons.holiday_village_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Bez naselja'),
                    ),
                    for (final settlement in _settlementsForSelectedMunicipality)
                      DropdownMenuItem(
                        value: settlement.id,
                        child: Text(settlement.name),
                      ),
                  ],
                  validator: _settlementValidator,
                  onChanged: _selectedMunicipalityId == null
                      ? null
                      : (value) =>
                            _onSettlementChanged(value == 0 ? null : value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _streetCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ulica',
                    prefixIcon: Icon(Icons.signpost_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _houseNumberCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Broj',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                _StatusSwitchField(
                  value: _isActive,
                  onChanged: widget.disableDeactivate
                      ? null
                      : (value) => setState(() => _isActive = value),
                  disabledHint: widget.disableDeactivate
                      ? 'Ne možete deaktivirati vlastiti nalog.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _passwordValidator,
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? 'Nova lozinka (ostavi prazno da zadržiš postojeću)'
                        : 'Lozinka',
                    prefixIcon: const Icon(Icons.lock_outline),
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

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return 'Unesite ispravan email.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return 'Unesite ispravan broj telefona.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (_isEdit) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    return null;
  }

  // Ime/Prezime are optional (a profile isn't required for every role), but
  // if either is filled in, both are required - CustomerProfile needs both.
  String? _firstNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _lastNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }

  String? _lastNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _firstNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }

  // Creating a brand new CustomerProfile requires a name (backend
  // CustomerProfileInsertValidator), so address input alone can't be saved
  // for a user who doesn't have a profile yet - guard against silently
  // dropping it instead of just leaving it unsent.
  String? _settlementValidator(int? _) {
    final hasAddressInput = _selectedSettlementId != null ||
        _streetCtrl.text.trim().isNotEmpty ||
        _houseNumberCtrl.text.trim().isNotEmpty;
    if (hasAddressInput && !_hasProfileInput) {
      return 'Unesite ime i prezime da biste sačuvali adresu.';
    }
    return null;
  }
}

class _StatusSwitchField extends StatelessWidget {
  const _StatusSwitchField({
    required this.value,
    required this.onChanged,
    this.disabledHint,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final switchWidget = Switch(value: value, onChanged: onChanged);

    final field = Container(
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
              value ? 'Aktivan' : 'Neaktivan',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          disabledHint == null
              ? switchWidget
              : Tooltip(message: disabledHint!, child: switchWidget),
        ],
      ),
    );

    if (disabledHint == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 6),
        Text(
          disabledHint!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
  const _EmptyState({required this.mode, required this.hasFilters});

  final AdminUsersScreenMode mode;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.people_outline,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'Nema ${mode.singularAccusative} za zadane filtere.'
                : 'Nema ${mode.singularAccusative}.',
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

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}

T? _findById<T>(List<T> items, int id, {required int Function(T) idOf}) {
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}
