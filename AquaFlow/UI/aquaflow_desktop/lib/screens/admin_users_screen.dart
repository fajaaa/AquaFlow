import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_city.dart';
import 'package:aquaflow_desktop/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/models/admin_municipality.dart';
import 'package:aquaflow_desktop/models/admin_settlement.dart';
import 'package:aquaflow_desktop/models/admin_user.dart';
import 'package:aquaflow_desktop/models/admin_user_draft.dart';
import 'package:aquaflow_desktop/models/admin_user_role_option.dart';
import 'package:aquaflow_desktop/screens/admin_user_activity_logs_screen.dart';
import 'package:aquaflow_desktop/screens/admin_user_water_meters_screen.dart';
import 'package:aquaflow_desktop/services/admin_city_exception.dart';
import 'package:aquaflow_desktop/services/admin_city_service.dart';
import 'package:aquaflow_desktop/services/admin_municipality_exception.dart';
import 'package:aquaflow_desktop/services/admin_municipality_service.dart';
import 'package:aquaflow_desktop/services/admin_settlement_exception.dart';
import 'package:aquaflow_desktop/services/admin_settlement_service.dart';
import 'package:aquaflow_desktop/services/admin_user_exception.dart';
import 'package:aquaflow_desktop/services/admin_user_service.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

/// Which role this screen manages. The listing is pinned server-side to that
/// role and the editor dialog creates users with it, so "Korisnici" manages
/// customers and "Administratori" manages admins (collectors have their own
/// screen over /CollectorProfiles).
enum AdminUsersScreenMode {
  customers(
    roleName: 'Customer',
    showWaterMeters: true,
    usesCustomerProfile: true,
  ),
  admins(roleName: 'Admin', showWaterMeters: false, usesCustomerProfile: false);

  const AdminUsersScreenMode({
    required this.roleName,
    required this.showWaterMeters,
    required this.usesCustomerProfile,
  });

  /// Backend `UserRole` name, sent as the `UserRole=` filter and used to
  /// resolve the role id for the editor dialog.
  final String roleName;

  /// Customers have water meters; admins do not, so the action is hidden.
  final bool showWaterMeters;

  /// Whether this role stores its name/address/language/theme in a
  /// CustomerProfile (Customer) - if false (Admin), the role has no
  /// CustomerProfile at all and the editor writes name straight to
  /// `User.FirstName/LastName` instead, hiding the Adresa/Jezik/Tema fields
  /// that only make sense for a CustomerProfile.
  final bool usesCustomerProfile;
}

/// Localized display text for [AdminUsersScreenMode], kept as an extension
/// (rather than fields on the enum) since a const enum constructor can't call
/// `AppLocalizations.of(context)`. Bosnian's grammatical cases mean most of
/// these are independent per-mode sentences, not a single template with a
/// word substituted in - e.g. "Nema korisnika."/"No customers." doesn't
/// compose from a shared "customer(s)" fragment the way the English side
/// would suggest.
extension AdminUsersScreenModeText on AdminUsersScreenMode {
  String title(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.usersLabel,
    AdminUsersScreenMode.admins => loc.administratorsLabel,
  };

  String subtitle(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.usersScreenSubtitle,
    AdminUsersScreenMode.admins => loc.administratorsScreenSubtitle,
  };

  String newButtonLabel(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.newUserButtonLabel,
    AdminUsersScreenMode.admins => loc.newAdministratorButtonLabel,
  };

  String editDialogTitle(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.editUserDialogTitle,
    AdminUsersScreenMode.admins => loc.editAdministratorDialogTitle,
  };

  String createdSuccessMessage(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.userCreatedSuccess,
    AdminUsersScreenMode.admins => loc.administratorCreatedSuccess,
  };

  String savedSuccessMessage(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.userSavedSuccess,
    AdminUsersScreenMode.admins => loc.administratorSavedSuccess,
  };

  String deleteDialogTitle(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.deleteUserDialogTitle,
    AdminUsersScreenMode.admins => loc.deleteAdministratorDialogTitle,
  };

  String deleteDialogContent(AppLocalizations loc, String email) =>
      switch (this) {
        AdminUsersScreenMode.customers => loc.deleteUserDialogContent(email),
        AdminUsersScreenMode.admins => loc.deleteAdministratorDialogContent(
          email,
        ),
      };

  String deletedSuccessMessage(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.userDeletedSuccess,
    AdminUsersScreenMode.admins => loc.administratorDeletedSuccess,
  };

  String emptyMessage(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.usersEmptyMessage,
    AdminUsersScreenMode.admins => loc.administratorsEmptyMessage,
  };

  String emptyFilteredMessage(AppLocalizations loc) => switch (this) {
    AdminUsersScreenMode.customers => loc.usersEmptyFilteredMessage,
    AdminUsersScreenMode.admins => loc.administratorsEmptyFilteredMessage,
  };
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

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with PagedListController<AdminUser, AdminUsersScreen> {
  final AdminUserService _service = AdminUserService();
  final AdminCityService _cityService = AdminCityService();
  final AdminMunicipalityService _municipalityService =
      AdminMunicipalityService();
  final AdminSettlementService _settlementService = AdminSettlementService();

  List<AdminUserRoleOption> _roles = [];
  List<AdminCity> _cities = [];
  List<AdminMunicipality> _municipalities = [];
  List<AdminSettlement> _settlements = [];
  // Naselje per row (customers mode only) - CustomerProfile.SettlementName
  // isn't flattened onto UserResponse, so it's fetched per row after each
  // page load and cached here rather than requiring a backend change.
  Map<int, String> _settlementNameByUserId = {};
  bool _locationLookupsLoading = false;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    load();
    _loadRoles();
  }

  @override
  Future<({List<AdminUser> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      name: searchController.text,
      userRole: widget.mode.roleName,
      isActive: _activeFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    // error.message already carries the backend's error text (e.g. the FK
    // Restrict message when a user has related records), not a generic one.
    return error is AdminUserException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  // The settlement-name lookup has to refresh after every load (search, page
  // change, filter, refresh, and post-mutation reload), not just the one
  // explicit call site this screen owns - so it hooks into `load()` itself
  // rather than a local wrapper, since every mixin method that reloads data
  // (queueSearch/submitSearch/clearSearch/goToPage/setPageSize/runMutation)
  // routes through this override.
  @override
  Future<void> load({bool resetPage = false}) async {
    await super.load(resetPage: resetPage);
    if (!mounted || widget.mode != AdminUsersScreenMode.customers) return;
    unawaited(_loadSettlementNames(items));
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _service.fetchRoles();
      if (!mounted) return;
      setState(() => _roles = roles);
    } on AdminUserException catch (e) {
      if (!mounted) return;
      showError(e.message);
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
      if (mounted) showError(e.message);
    } on AdminMunicipalityException catch (e) {
      if (mounted) showError(e.message);
    } on AdminSettlementException catch (e) {
      if (mounted) showError(e.message);
    } finally {
      if (mounted) setState(() => _locationLookupsLoading = false);
    }
  }

  /// Fetches each row's CustomerProfile to populate the "Naselje" column.
  /// Runs in the background after the page renders, so a slow lookup doesn't
  /// delay the table itself; guarded against a stale response overwriting a
  /// newer page's data by checking [forItems] is still the mixin's current
  /// `items` list (a fresh list instance is assigned on every load).
  Future<void> _loadSettlementNames(List<AdminUser> forItems) async {
    final entries = await Future.wait(
      forItems.map((user) async {
        try {
          final profile = await _service.fetchCustomerProfile(user.id);
          return MapEntry(user.id, profile?.settlementName ?? '');
        } on AdminUserException {
          return MapEntry(user.id, '');
        }
      }),
    );
    if (!mounted || !identical(items, forItems)) return;
    setState(() => _settlementNameByUserId = Map.fromEntries(entries));
  }

  void _setActiveFilter(String value) {
    final selected = value == 'active'
        ? true
        : (value == 'inactive' ? false : null);
    if (selected == _activeFilter) return;
    setState(() => _activeFilter = selected);
    load(resetPage: true);
  }

  int? get _currentUserId => context.read<AuthProvider>().session?.id;

  /// Resolves the id of the role this screen manages ([AdminUsersScreenMode]
  /// pins the whole screen to one role), or null with an error snackbar when
  /// the roles can't be loaded or the role name doesn't exist on the backend.
  Future<int?> _resolvePinnedRoleId() async {
    final loc = AppLocalizations.of(context);
    if (_roles.isEmpty) {
      await _loadRoles();
      if (!mounted) return null;
      if (_roles.isEmpty) {
        showError(loc.rolesNotLoadedError);
        return null;
      }
    }

    final roleName = widget.mode.roleName.toLowerCase();
    for (final role in _roles) {
      if (role.name.toLowerCase() == roleName) return role.id;
    }
    showError(loc.roleNotFoundError(widget.mode.roleName));
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

    await runMutation(() async {
      await _service.create(draft);
    }, widget.mode.createdSuccessMessage(AppLocalizations.of(context)));
  }

  Future<void> _openEdit(AdminUser user) async {
    final roleId = await _resolvePinnedRoleId();
    if (!mounted || roleId == null) return;
    await _ensureLocationLookupsLoaded();
    if (!mounted) return;

    AdminCustomerProfile? existingProfile;
    if (widget.mode.usesCustomerProfile) {
      try {
        existingProfile = await _service.fetchCustomerProfile(user.id);
      } on AdminUserException catch (e) {
        if (!mounted) return;
        showError(e.message);
      }
      if (!mounted) return;
    }

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

    await runMutation(() async {
      await _service.update(
        user.id,
        draft,
        existingProfileId: existingProfile?.id,
      );
    }, widget.mode.savedSuccessMessage(AppLocalizations.of(context)));
  }

  void _openWaterMeters(AdminUser user) {
    context.pushScreen(AdminUserWaterMetersScreen(user: user));
  }

  void _openActivityLogs(AdminUser user) {
    final name = user.fullName;
    context.pushScreen(
      AdminUserActivityLogsScreen(
        userId: user.id,
        displayName: name.isEmpty ? user.email : name,
      ),
    );
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.mode.deleteDialogTitle(loc)),
        content: Text(widget.mode.deleteDialogContent(loc, user.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.dialogDismissButton),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(loc.commonDelete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.delete(user.id);
      if (items.length == 1 && page > 1) {
        page -= 1;
      }
    }, widget.mode.deletedSuccessMessage(AppLocalizations.of(context)));
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    _cityService.dispose();
    _municipalityService.dispose();
    _settlementService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                  title: widget.mode.title(loc),
                  subtitle: widget.mode.subtitle(loc),
                  actions: [
                    RefreshButton(
                      onRefresh: () async {
                        await load();
                        await _loadRoles();
                      },
                      enabled: !mutating,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: loading || mutating ? null : _openCreate,
                      icon: const Icon(Icons.add),
                      label: Text(widget.mode.newButtonLabel(loc)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFilters(loc),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(loc)),
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
      ),
    );
  }

  Widget _buildFilters(AppLocalizations loc) {
    final hasSearch = searchController.text.trim().isNotEmpty;
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
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: loc.commonSearch,
              hintText: loc.nameSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearch
                  ? IconButton(
                      tooltip: loc.clearSearchTooltip,
                      onPressed: clearSearch,
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
            decoration: InputDecoration(
              labelText: loc.statusFieldLabel,
              prefixIcon: const Icon(Icons.toggle_on_outlined),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(loc.allOption)),
              DropdownMenuItem(value: 'active', child: Text(loc.statusActive)),
              DropdownMenuItem(
                value: 'inactive',
                child: Text(loc.statusInactive),
              ),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setActiveFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: loc.applyFiltersTooltip,
          onPressed: loading || mutating ? null : () => load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }

    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline,
        message: widget.mode.emptyMessage(loc),
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: widget.mode.emptyFilteredMessage(loc),
      );
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
                      DataColumn(label: Text(loc.fullNameColumnLabel)),
                      DataColumn(label: Text(loc.fieldEmailLabel)),
                      DataColumn(label: Text(loc.fieldPhoneLabel)),
                      if (widget.mode == AdminUsersScreenMode.customers)
                        DataColumn(label: Text(loc.locationSettlementLabel)),
                      DataColumn(label: Text(loc.statusFieldLabel)),
                      DataColumn(label: Text(loc.createdColumnLabel)),
                      DataColumn(label: Text(loc.actionsColumnLabel)),
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
                              TableRowActions(
                                disabled: mutating,
                                extraActions: [
                                  IconButton(
                                    tooltip: loc.commonEdit,
                                    onPressed: mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  if (widget.mode.showWaterMeters)
                                    IconButton(
                                      tooltip: loc.waterMetersTooltip,
                                      onPressed: mutating
                                          ? null
                                          : () => _openWaterMeters(item),
                                      icon: const Icon(
                                        Icons.water_drop_outlined,
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: loc.activitiesTooltip,
                                    onPressed: mutating
                                        ? null
                                        : () => _openActivityLogs(item),
                                    icon: const Icon(Icons.history_outlined),
                                  ),
                                  IconButton(
                                    tooltip: item.id == currentUserId
                                        ? loc.cannotDeleteOwnAccountError
                                        : loc.commonDelete,
                                    onPressed:
                                        mutating || item.id == currentUserId
                                        ? null
                                        : () => _confirmDelete(item),
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

  bool get _hasFilters =>
      searchController.text.trim().isNotEmpty || _activeFilter != null;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B);
    final label = isActive ? loc.statusActive : loc.statusInactive;
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
      _firstNameCtrl.text.trim().isNotEmpty ||
      _lastNameCtrl.text.trim().isNotEmpty;

  List<AdminMunicipality> get _municipalitiesForSelectedCity => widget
      .municipalities
      .where((municipality) => municipality.cityId == _selectedCityId)
      .toList();

  List<AdminSettlement> get _settlementsForSelectedMunicipality => widget
      .settlements
      .where(
        (settlement) => settlement.municipalityId == _selectedMunicipalityId,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    final profile = widget.existingProfile;
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _isActive = user?.isActive ?? true;
    if (widget.mode.usesCustomerProfile) {
      _firstNameCtrl.text = profile?.firstName ?? '';
      _lastNameCtrl.text = profile?.lastName ?? '';
    } else {
      // No CustomerProfile for this role - the name lives directly on User.
      _firstNameCtrl.text = user?.firstName ?? '';
      _lastNameCtrl.text = user?.lastName ?? '';
    }
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
        profile: widget.mode.usesCustomerProfile && _hasProfileInput
            ? AdminCustomerProfileDraft(
                firstName: _firstNameCtrl.text.trim(),
                lastName: _lastNameCtrl.text.trim(),
                theme: _theme,
                settlementId: _selectedSettlementId,
                street: street.isEmpty ? null : street,
                houseNumber: houseNumber.isEmpty ? null : houseNumber,
              )
            : null,
        firstName: widget.mode.usesCustomerProfile
            ? null
            : _firstNameCtrl.text.trim(),
        lastName: widget.mode.usesCustomerProfile
            ? null
            : _lastNameCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        _isEdit
            ? widget.mode.editDialogTitle(loc)
            : widget.mode.newButtonLabel(loc),
      ),
      content: SizedBox(
        width: math.min(760, MediaQuery.sizeOf(context).width - 48),
        height: math.min(560, MediaQuery.sizeOf(context).height - 120),
        child: SingleChildScrollView(
          // Top padding so a focused/filled field's floating label - which
          // sits half above the field's own box - has room to render without
          // being clipped by the scroll viewport.
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormSectionHeader(loc.profileSectionLabel),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: _firstNameValidator,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: loc.fieldFirstNameLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: _lastNameValidator,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: loc.fieldLastNameLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.existingProfile != null) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    key: ValueKey(widget.existingProfile!.customerCode),
                    initialValue: widget.existingProfile!.customerCode,
                    enabled: false,
                    style: const TextStyle(letterSpacing: 0.6),
                    decoration: InputDecoration(
                      labelText: loc.customerCodeFieldLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
                if (widget.mode.usesCustomerProfile) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _theme,
                    decoration: InputDecoration(
                      labelText: loc.registerThemeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(loc.themeLightOption),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(loc.themeDarkOption),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _theme = value);
                    },
                  ),
                ],
                const SizedBox(height: 22),

                _FormSectionHeader(loc.contactSectionLabel),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                        decoration: InputDecoration(
                          labelText: loc.fieldEmailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        validator: _phoneValidator,
                        decoration: InputDecoration(
                          labelText: loc.fieldPhoneLabel,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                if (widget.mode.usesCustomerProfile) ...[
                  _FormSectionHeader(loc.addressLabel),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedCityId ?? 0,
                          decoration: InputDecoration(
                            labelText: loc.locationCityLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(loc.locationNoCityOption),
                            ),
                            for (final city in widget.cities)
                              DropdownMenuItem(
                                value: city.id,
                                child: Text(city.name),
                              ),
                          ],
                          onChanged: (value) =>
                              _onCityChanged(value == 0 ? null : value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMunicipalityId ?? 0,
                          decoration: InputDecoration(
                            labelText: loc.locationMunicipalityLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(loc.locationNoMunicipalityOption),
                            ),
                            for (final municipality
                                in _municipalitiesForSelectedCity)
                              DropdownMenuItem(
                                value: municipality.id,
                                child: Text(municipality.name),
                              ),
                          ],
                          onChanged: _selectedCityId == null
                              ? null
                              : (value) => _onMunicipalityChanged(
                                  value == 0 ? null : value,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSettlementId ?? 0,
                          decoration: InputDecoration(
                            labelText: loc.locationSettlementLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(loc.locationNoSettlementOption),
                            ),
                            for (final settlement
                                in _settlementsForSelectedMunicipality)
                              DropdownMenuItem(
                                value: settlement.id,
                                child: Text(settlement.name),
                              ),
                          ],
                          validator: _settlementValidator,
                          onChanged: _selectedMunicipalityId == null
                              ? null
                              : (value) => _onSettlementChanged(
                                  value == 0 ? null : value,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _streetCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: loc.locationStreetLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _houseNumberCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: loc.locationHouseNumberLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],

                _FormSectionHeader(loc.accountSectionLabel),
                _StatusSwitchField(
                  value: _isActive,
                  onChanged: widget.disableDeactivate
                      ? null
                      : (value) => setState(() => _isActive = value),
                  disabledHint: widget.disableDeactivate
                      ? loc.cannotDeactivateOwnAccountError
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
                        ? loc.newPasswordOptionalLabel
                        : loc.fieldPasswordLabel,
                    prefixIcon: const Icon(Icons.password_outlined),
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
          child: Text(loc.dialogDismissButton),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(loc.commonSave),
        ),
      ],
    );
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    final loc = AppLocalizations.of(context);
    if (text.isEmpty) return loc.fieldRequiredError;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return loc.emailInvalidError;
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return AppLocalizations.of(context).phoneInvalidNumberError;
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (_isEdit) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppLocalizations.of(context).fieldRequiredError;
    return null;
  }

  // Ime/Prezime are optional (a profile isn't required for every role), but
  // if either is filled in, both are required - CustomerProfile needs both.
  String? _firstNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _lastNameCtrl.text.trim().isNotEmpty) {
      return AppLocalizations.of(context).nameRequiredTogetherError;
    }
    return null;
  }

  String? _lastNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _firstNameCtrl.text.trim().isNotEmpty) {
      return AppLocalizations.of(context).nameRequiredTogetherError;
    }
    return null;
  }

  // Creating a brand new CustomerProfile requires a name (backend
  // CustomerProfileInsertValidator), so address input alone can't be saved
  // for a user who doesn't have a profile yet - guard against silently
  // dropping it instead of just leaving it unsent.
  String? _settlementValidator(int? _) {
    final hasAddressInput =
        _selectedSettlementId != null ||
        _streetCtrl.text.trim().isNotEmpty ||
        _houseNumberCtrl.text.trim().isNotEmpty;
    if (hasAddressInput && !_hasProfileInput) {
      return AppLocalizations.of(context).nameRequiredForAddressError;
    }
    return null;
  }
}

/// Small uppercase label introducing a group of related fields in the editor
/// dialog ("Profil", "Kontakt", "Adresa", "Nalog") - mirrors the sidebar's
/// category-group header typography so field grouping reads consistently
/// with the rest of the desktop app.
class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFF64748B),
        ),
      ),
    );
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
    final loc = AppLocalizations.of(context);
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
              value ? loc.statusActive : loc.statusInactive,
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
