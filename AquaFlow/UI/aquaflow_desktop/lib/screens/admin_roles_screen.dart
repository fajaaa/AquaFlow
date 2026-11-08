import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_role.dart';
import 'package:aquaflow_desktop/services/admin_role_exception.dart';
import 'package:aquaflow_desktop/services/admin_role_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

/// Admin CRUD for roles, permissions and the role-permission assignments.
class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: ScreenHeader(
                title: loc.rolesPermissionsNavLabel,
                subtitle: loc.rolesPermissionsSubtitle,
                actions: const [],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: [
                Tab(text: loc.rolesTabRoles),
                Tab(text: loc.rolesTabPermissions),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [_RolesTab(), _PermissionsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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

Widget _activePill(AppLocalizations loc, bool active) => active
    ? _Pill(
        label: loc.tariffStatusActive,
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
      )
    : _Pill(
        label: loc.tariffStatusInactive,
        color: const Color(0xFF64748B),
        icon: Icons.block_outlined,
      );

Widget _systemCell(AppLocalizations loc, bool isSystem) => isSystem
    ? _Pill(
        label: loc.systemBadgeLabel,
        color: const Color(0xFF1565C0),
        icon: Icons.lock_outline,
      )
    : const SizedBox.shrink();

Widget _textCell(String text, {double width = 240}) => Tooltip(
  message: text,
  child: SizedBox(
    width: width,
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
  ),
);

Widget _tableShell(BuildContext context, BoxConstraints constraints, Widget table) {
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.30),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          ),
        ),
      ),
    ),
  );
}

Future<bool> _confirmDelete(
  BuildContext context,
  String title,
  String content,
) async {
  final loc = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
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
  return confirmed == true;
}

String? _required(BuildContext context, String? value) =>
    value == null || value.trim().isEmpty
    ? AppLocalizations.of(context).fieldRequiredError
    : null;

// ---------------------------------------------------------------------------
// Roles tab
// ---------------------------------------------------------------------------

class _RolesTab extends StatefulWidget {
  const _RolesTab();

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab>
    with PagedListController<AdminRole, _RolesTab> {
  final AdminRoleService _service = AdminRoleService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminRole> items, int totalCount})> fetchPage() async {
    final data = await _service.fetchRoles(
      page: page,
      pageSize: pageSize,
      name: searchController.text,
    );
    return (items: data.items, totalCount: data.totalCount);
  }

  @override
  String describeError(Object error) => error is AdminRoleException
      ? error.message
      : AppLocalizations.of(context).unexpectedError;

  Future<void> _openCreate() async {
    final draft = await showDialog<AdminRoleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RoleEditorDialog(),
    );
    if (!mounted || draft == null) return;
    await runMutation(
      () => _service.createRole(draft),
      AppLocalizations.of(context).roleCreatedSuccess,
    );
  }

  Future<void> _openEdit(AdminRole role) async {
    final draft = await showDialog<AdminRoleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoleEditorDialog(role: role),
    );
    if (!mounted || draft == null) return;
    await runMutation(
      () => _service.updateRole(role.id, draft),
      AppLocalizations.of(context).roleSavedSuccess,
    );
  }

  Future<void> _delete(AdminRole role) async {
    final loc = AppLocalizations.of(context);
    final ok = await _confirmDelete(
      context,
      loc.deleteRoleDialogTitle,
      loc.deleteRoleDialogContent,
    );
    if (!mounted || !ok) return;
    await runMutation(() async {
      await _service.deleteRole(role.id);
      if (items.length == 1 && page > 1) page -= 1;
    }, loc.roleDeletedSuccess);
  }

  Future<void> _openPermissions(AdminRole role) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RolePermissionsDialog(role: role, service: _service),
    );
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasSearch = searchController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: queueSearch,
                  onSubmitted: submitSearch,
                  decoration: InputDecoration(
                    labelText: loc.nameColumnLabel,
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
              RefreshButton(onRefresh: () => load(), enabled: !mutating),
              FilledButton.icon(
                onPressed: loading || mutating ? null : _openCreate,
                icon: const Icon(Icons.add),
                label: Text(loc.newRoleButtonLabel),
              ),
            ],
          ),
        ),
        if ((loading && !isInitialLoad) || mutating)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _content(loc, hasSearch)),
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

  Widget _content(AppLocalizations loc, bool hasSearch) {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.admin_panel_settings_outlined,
        message: loc.noRolesMessage,
        hasFilters: hasSearch,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.rolesPermissionsEmptyFilteredMessage,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _tableShell(
        context,
        constraints,
        DataTable(
          dataRowMinHeight: 60,
          dataRowMaxHeight: 68,
          columns: [
            DataColumn(label: Text(loc.nameColumnLabel)),
            DataColumn(label: Text(loc.descriptionColumnLabel)),
            DataColumn(label: Text(loc.statusFieldLabel)),
            DataColumn(label: Text(loc.systemColumnLabel)),
            DataColumn(label: Text(loc.actionsColumnLabel)),
          ],
          rows: [
            for (final role in items)
              DataRow(
                onSelectChanged: (_) => _openEdit(role),
                cells: [
                  DataCell(Text(role.name)),
                  DataCell(_textCell(role.description)),
                  DataCell(_activePill(loc, role.isActive)),
                  DataCell(_systemCell(loc, role.isSystem)),
                  DataCell(
                    TableRowActions(
                      disabled: mutating,
                      onEdit: () => _openEdit(role),
                      onDelete: role.isSystem ? null : () => _delete(role),
                      extraActions: [
                        IconButton(
                          tooltip: loc.rolePermissionsAction,
                          onPressed: mutating
                              ? null
                              : () => _openPermissions(role),
                          icon: const Icon(Icons.key_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleEditorDialog extends StatefulWidget {
  const _RoleEditorDialog({this.role});

  final AdminRole? role;

  @override
  State<_RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<_RoleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  late bool _isActive;

  bool get _isEdit => widget.role != null;
  bool get _isSystem => widget.role?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    _nameCtrl.text = role?.name ?? '';
    _descriptionCtrl.text = role?.description ?? '';
    _isActive = role?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AdminRoleDraft(
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEdit ? loc.editRoleDialogTitle : loc.newRoleButtonLabel),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  readOnly: _isSystem,
                  maxLength: 30,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(context, value),
                  decoration: InputDecoration(
                    labelText: loc.nameColumnLabel,
                    prefixIcon: Icon(
                      _isSystem ? Icons.lock_outline : Icons.label_outline,
                    ),
                    helperText: _isSystem ? loc.systemItemLockedHint : null,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: loc.descriptionColumnLabel,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.tariffStatusActive),
                  value: _isActive,
                  onChanged: _isSystem
                      ? null
                      : (value) => setState(() => _isActive = value),
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
}

// ---------------------------------------------------------------------------
// Role permissions dialog
// ---------------------------------------------------------------------------

class _RolePermissionsDialog extends StatefulWidget {
  const _RolePermissionsDialog({required this.role, required this.service});

  final AdminRole role;
  final AdminRoleService service;

  @override
  State<_RolePermissionsDialog> createState() => _RolePermissionsDialogState();
}

class _RolePermissionsDialogState extends State<_RolePermissionsDialog> {
  List<AdminPermission> _permissions = const [];
  // permissionId -> UserRolePermission id (what DELETE needs).
  final Map<int, int> _assignments = {};
  final Set<int> _busy = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final permissions = await widget.service.fetchAllPermissions();
      final assigned = await widget.service.fetchRolePermissions(
        widget.role.id,
      );
      if (!mounted) return;
      setState(() {
        _permissions = permissions;
        _assignments
          ..clear()
          ..addEntries(assigned.map((a) => MapEntry(a.permissionId, a.id)));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _describe(e);
        _loading = false;
      });
    }
  }

  String _describe(Object e) => e is AdminRoleException
      ? e.message
      : AppLocalizations.of(context).unexpectedError;

  Future<void> _toggle(AdminPermission permission, bool assign) async {
    setState(() {
      _busy.add(permission.id);
      _error = null;
    });
    try {
      if (assign) {
        final created = await widget.service.assign(
          widget.role.id,
          permission.id,
        );
        _assignments[permission.id] = created.id;
      } else {
        await widget.service.unassign(_assignments[permission.id]!);
        _assignments.remove(permission.id);
      }
    } catch (e) {
      // The checkbox is driven by _assignments, which is untouched on failure,
      // so it snaps back to its previous state.
      if (mounted) _error = _describe(e);
    } finally {
      if (mounted) setState(() => _busy.remove(permission.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final byModule = <String, List<AdminPermission>>{};
    for (final permission in _permissions) {
      byModule.putIfAbsent(permission.module, () => []).add(permission);
    }

    return AlertDialog(
      title: Text('${loc.rolePermissionsDialogTitle}: ${widget.role.name}'),
      content: SizedBox(
        width: math.min(620, MediaQuery.sizeOf(context).width - 48),
        height: math.min(560, MediaQuery.sizeOf(context).height - 200),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.rolePermissionsDialogHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final entry in byModule.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              entry.key.isEmpty ? '-' : entry.key,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          for (final permission in entry.value)
                            CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _assignments.containsKey(permission.id),
                              onChanged: _busy.contains(permission.id)
                                  ? null
                                  : (value) =>
                                        _toggle(permission, value ?? false),
                              title: Text(permission.name),
                              subtitle: Text(permission.code),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonClose),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Permissions tab
// ---------------------------------------------------------------------------

class _PermissionsTab extends StatefulWidget {
  const _PermissionsTab();

  @override
  State<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<_PermissionsTab>
    with PagedListController<AdminPermission, _PermissionsTab> {
  final AdminRoleService _service = AdminRoleService();
  final TextEditingController _codeController = TextEditingController();

  String _module = '';
  List<String> _modules = const [];

  @override
  void initState() {
    super.initState();
    load();
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final all = await _service.fetchAllPermissions();
      if (!mounted) return;
      setState(() {
        _modules = (all.map((p) => p.module).where((m) => m.isNotEmpty).toSet()
          ).toList()..sort();
        if (_module.isNotEmpty && !_modules.contains(_module)) _module = '';
      });
    } catch (_) {
      // The module filter is a convenience; the table reports its own errors.
    }
  }

  @override
  Future<({List<AdminPermission> items, int totalCount})> fetchPage() async {
    final data = await _service.fetchPermissions(
      page: page,
      pageSize: pageSize,
      code: _codeController.text,
      name: searchController.text,
      module: _module,
    );
    return (items: data.items, totalCount: data.totalCount);
  }

  @override
  String describeError(Object error) => error is AdminRoleException
      ? error.message
      : AppLocalizations.of(context).unexpectedError;

  Future<void> _openCreate() async {
    final draft = await showDialog<AdminPermissionDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PermissionEditorDialog(),
    );
    if (!mounted || draft == null) return;
    await runMutation(
      () => _service.createPermission(draft),
      AppLocalizations.of(context).permissionCreatedSuccess,
    );
    _loadModules();
  }

  Future<void> _openEdit(AdminPermission permission) async {
    final draft = await showDialog<AdminPermissionDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PermissionEditorDialog(permission: permission),
    );
    if (!mounted || draft == null) return;
    await runMutation(
      () => _service.updatePermission(permission.id, draft),
      AppLocalizations.of(context).permissionSavedSuccess,
    );
    _loadModules();
  }

  Future<void> _delete(AdminPermission permission) async {
    final loc = AppLocalizations.of(context);
    final ok = await _confirmDelete(
      context,
      loc.deletePermissionDialogTitle,
      loc.deletePermissionDialogContent,
    );
    if (!mounted || !ok) return;
    await runMutation(() async {
      await _service.deletePermission(permission.id);
      if (items.length == 1 && page > 1) page -= 1;
    }, loc.permissionDeletedSuccess);
    _loadModules();
  }

  @override
  void dispose() {
    _codeController.dispose();
    disposeController();
    _service.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _codeController.text.trim().isNotEmpty ||
      searchController.text.trim().isNotEmpty ||
      _module.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: _filters(loc),
        ),
        if ((loading && !isInitialLoad) || mutating)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _content(loc)),
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

  Widget _filters(AppLocalizations loc) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _codeController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => load(resetPage: true),
            decoration: InputDecoration(
              labelText: loc.codeColumnLabel,
              prefixIcon: const Icon(Icons.tag),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: loc.nameColumnLabel,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _module,
            decoration: InputDecoration(
              labelText: loc.moduleColumnLabel,
              prefixIcon: const Icon(Icons.filter_alt_outlined),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(loc.allOption)),
              for (final module in _modules)
                DropdownMenuItem(value: module, child: Text(module)),
            ],
            onChanged: loading || mutating
                ? null
                : (value) {
                    setState(() => _module = value ?? '');
                    load(resetPage: true);
                  },
          ),
        ),
        IconButton.filledTonal(
          tooltip: loc.applyFiltersTooltip,
          onPressed: loading || mutating ? null : () => load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
        RefreshButton(onRefresh: () => load(), enabled: !mutating),
        FilledButton.icon(
          onPressed: loading || mutating ? null : _openCreate,
          icon: const Icon(Icons.add),
          label: Text(loc.newPermissionButtonLabel),
        ),
      ],
    );
  }

  Widget _content(AppLocalizations loc) {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.key_outlined,
        message: loc.noPermissionsMessage,
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.rolesPermissionsEmptyFilteredMessage,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _tableShell(
        context,
        constraints,
        DataTable(
          dataRowMinHeight: 60,
          dataRowMaxHeight: 68,
          columns: [
            DataColumn(label: Text(loc.codeColumnLabel)),
            DataColumn(label: Text(loc.nameColumnLabel)),
            DataColumn(label: Text(loc.moduleColumnLabel)),
            DataColumn(label: Text(loc.descriptionColumnLabel)),
            DataColumn(label: Text(loc.statusFieldLabel)),
            DataColumn(label: Text(loc.systemColumnLabel)),
            DataColumn(label: Text(loc.actionsColumnLabel)),
          ],
          rows: [
            for (final permission in items)
              DataRow(
                onSelectChanged: (_) => _openEdit(permission),
                cells: [
                  DataCell(Text(permission.code)),
                  DataCell(_textCell(permission.name, width: 200)),
                  DataCell(Text(permission.module)),
                  DataCell(_textCell(permission.description)),
                  DataCell(_activePill(loc, permission.isActive)),
                  DataCell(_systemCell(loc, permission.isSystem)),
                  DataCell(
                    TableRowActions(
                      disabled: mutating,
                      onEdit: () => _openEdit(permission),
                      onDelete: permission.isSystem
                          ? null
                          : () => _delete(permission),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionEditorDialog extends StatefulWidget {
  const _PermissionEditorDialog({this.permission});

  final AdminPermission? permission;

  @override
  State<_PermissionEditorDialog> createState() =>
      _PermissionEditorDialogState();
}

class _PermissionEditorDialogState extends State<_PermissionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  late bool _isActive;

  bool get _isEdit => widget.permission != null;
  bool get _isSystem => widget.permission?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    final permission = widget.permission;
    _codeCtrl.text = permission?.code ?? '';
    _nameCtrl.text = permission?.name ?? '';
    _moduleCtrl.text = permission?.module ?? '';
    _descriptionCtrl.text = permission?.description ?? '';
    _isActive = permission?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _moduleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AdminPermissionDraft(
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        module: _moduleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        _isEdit ? loc.editPermissionDialogTitle : loc.newPermissionButtonLabel,
      ),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeCtrl,
                  readOnly: _isSystem,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(context, value),
                  decoration: InputDecoration(
                    labelText: loc.codeColumnLabel,
                    prefixIcon: Icon(
                      _isSystem ? Icons.lock_outline : Icons.tag,
                    ),
                    helperText: _isSystem ? loc.systemItemLockedHint : null,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(context, value),
                  decoration: InputDecoration(
                    labelText: loc.nameColumnLabel,
                    prefixIcon: const Icon(Icons.label_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _moduleCtrl,
                  maxLength: 50,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: loc.moduleColumnLabel,
                    prefixIcon: const Icon(Icons.folder_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: loc.descriptionColumnLabel,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.tariffStatusActive),
                  value: _isActive,
                  onChanged: _isSystem
                      ? null
                      : (value) => setState(() => _isActive = value),
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
}
