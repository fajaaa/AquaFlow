import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_collector_profile_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_option.dart';
import 'package:aquaflow_desktop/admin/models/admin_user.dart';
import 'package:aquaflow_desktop/admin/screens/admin_user_activity_logs_screen.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_service.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminCollectorsScreen extends StatefulWidget {
  const AdminCollectorsScreen({super.key});

  @override
  State<AdminCollectorsScreen> createState() => _AdminCollectorsScreenState();
}

class _AdminCollectorsScreenState extends State<AdminCollectorsScreen>
    with PagedListController<AdminCollectorProfile, AdminCollectorsScreen> {
  final AdminCollectorService _service = AdminCollectorService();

  List<AdminUser> _collectorUsers = const [];
  List<AdminSettlementOption> _settlements = const [];
  bool _lookupsLoading = false;

  @override
  void initState() {
    super.initState();
    load();
    _loadLookups(showErrors: false);
  }

  @override
  Future<({List<AdminCollectorProfile> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetchCollectors(
      page: page,
      pageSize: pageSize,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminCollectorException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  Future<bool> _loadLookups({bool showErrors = true}) async {
    if (_lookupsLoading) return false;

    setState(() => _lookupsLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchCollectorUsers(),
        _service.fetchSettlements(),
      ]);
      if (!mounted) return false;
      setState(() {
        _collectorUsers = results[0] as List<AdminUser>;
        _settlements = results[1] as List<AdminSettlementOption>;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (showErrors) showError(describeError(e));
      return false;
    } finally {
      if (mounted) setState(() => _lookupsLoading = false);
    }
  }

  Future<bool> _loadSettlements({bool showErrors = true}) async {
    if (_lookupsLoading) return false;

    setState(() => _lookupsLoading = true);
    try {
      final settlements = await _service.fetchSettlements();
      if (!mounted) return false;
      setState(() => _settlements = settlements);
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (showErrors) showError(describeError(e));
      return false;
    } finally {
      if (mounted) setState(() => _lookupsLoading = false);
    }
  }

  void _openActivityLogs(AdminCollectorProfile profile) {
    context.pushScreen(
      AdminUserActivityLogsScreen(
        userId: profile.userId,
        displayName: profile.label,
      ),
    );
  }

  Future<void> _openCreate() async {
    final loaded = await _loadSettlements();
    if (!mounted || !loaded) return;

    final draft = await showDialog<_CollectorCreateDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CollectorCreateDialog(settlements: _settlements),
    );
    if (!mounted || draft == null) return;

    await _runMutation(
      () async {
        await _service.createCollectorUserWithProfile(
          email: draft.email,
          password: draft.password,
          phone: draft.phone,
          firstName: draft.firstName,
          lastName: draft.lastName,
          assignedAreaId: draft.assignedAreaId,
        );
      },
      'Inkasant je dodan.',
      resetPageAfterSuccess: true,
    );
  }

  Future<void> _openEdit(AdminCollectorProfile collector) async {
    final loaded = await _loadLookups();
    if (!mounted || !loaded) return;

    final users = _usersIncludingCollector(collector);
    final draft = await showDialog<AdminCollectorProfileDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CollectorEditorDialog(
        collector: collector,
        users: users,
        settlements: _settlements,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.updateCollectorProfile(
        collector.id,
        draft.userId,
        draft.assignedAreaId,
      );
    }, 'Profil inkasanta je sačuvan.');
  }

  List<AdminUser> _usersIncludingCollector(AdminCollectorProfile collector) {
    if (_collectorUsers.any((user) => user.id == collector.userId)) {
      return _collectorUsers;
    }

    return [
      AdminUser(
        id: collector.userId,
        email: collector.email,
        phone: collector.phone,
        userRoleId: 0,
        userRole: 'Collector',
        isActive: collector.isActive,
        createdAt: null,
        firstName: collector.firstName,
        lastName: collector.lastName,
      ),
      ..._collectorUsers,
    ];
  }

  // The shared `runMutation` doesn't support an optional page reset or a
  // post-success lookups reload, both of which this screen's create/edit
  // flows need - so mutations keep this local wrapper, reusing `mutating`/
  // `load`/`showError`/`describeError` from the mixin.
  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage, {
    bool resetPageAfterSuccess = false,
  }) async {
    setState(() => mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await load(resetPage: resetPageAfterSuccess);
      await _loadLookups(showErrors: false);
    } catch (e) {
      if (!mounted) return;
      showError(describeError(e));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: ScreenHeader(
              title: 'Inkasanti',
              subtitle: 'Pregled i uređivanje profila inkasanata za terenski rad.',
              actions: [
                IconButton(
                  tooltip: 'Osvježi',
                  onPressed: loading || mutating || _lookupsLoading
                      ? null
                      : () {
                          load();
                          _loadLookups();
                        },
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: loading || mutating || _lookupsLoading
                      ? null
                      : _openCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj inkasanta'),
                ),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating || _lookupsLoading)
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
      return const EmptyStateView(
        icon: Icons.assignment_ind_outlined,
        message: 'Nema profila inkasanata.',
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
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('Ime i prezime')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Telefon')),
                      DataColumn(label: Text('Šifra inkasanta')),
                      DataColumn(label: Text('Područje')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(
                              Text(item.fullName.isEmpty ? '-' : item.fullName),
                            ),
                            DataCell(Text(_textOrDash(item.email))),
                            DataCell(Text(_textOrDash(item.phone))),
                            DataCell(Text(_textOrDash(item.employeeCode))),
                            DataCell(Text(item.areaLabel)),
                            DataCell(_StatusPill(isActive: item.isActive)),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                extraActions: [
                                  IconButton(
                                    tooltip: 'Uredi profil',
                                    onPressed: mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Aktivnosti',
                                    onPressed: mutating
                                        ? null
                                        : () => _openActivityLogs(item),
                                    icon: const Icon(Icons.history_outlined),
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

class _CollectorCreateDraft {
  const _CollectorCreateDraft({
    required this.email,
    required this.password,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.assignedAreaId,
  });

  final String email;
  final String password;
  final String phone;
  final String firstName;
  final String lastName;
  final int? assignedAreaId;
}

class _CollectorCreateDialog extends StatefulWidget {
  const _CollectorCreateDialog({required this.settlements});

  final List<AdminSettlementOption> settlements;

  @override
  State<_CollectorCreateDialog> createState() => _CollectorCreateDialogState();
}

class _CollectorCreateDialogState extends State<_CollectorCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  int? _assignedAreaId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _CollectorCreateDraft(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        assignedAreaId: _assignedAreaId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj inkasanta'),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GeneratedCodeInfo(),
                const SizedBox(height: 14),
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
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: _passwordValidator,
                  decoration: const InputDecoration(
                    labelText: 'Lozinka',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _assignedAreaId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Područje dodjele',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Bez dodijeljenog područja'),
                    ),
                    for (final settlement in widget.settlements)
                      DropdownMenuItem(
                        value: settlement.id,
                        child: Text(settlement.label),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _assignedAreaId = value == 0 ? null : value);
                  },
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
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    return null;
  }

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
}

class _CollectorEditorDialog extends StatefulWidget {
  const _CollectorEditorDialog({
    required this.users,
    required this.settlements,
    this.collector,
  });

  final List<AdminUser> users;
  final List<AdminSettlementOption> settlements;
  final AdminCollectorProfile? collector;

  @override
  State<_CollectorEditorDialog> createState() => _CollectorEditorDialogState();
}

class _CollectorEditorDialogState extends State<_CollectorEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _userId;
  int? _assignedAreaId;

  bool get _isEdit => widget.collector != null;

  @override
  void initState() {
    super.initState();

    final collector = widget.collector;
    final userIds = widget.users.map((user) => user.id).toSet();
    final areaIds = widget.settlements
        .map((settlement) => settlement.id)
        .toSet();

    _userId = collector != null && userIds.contains(collector.userId)
        ? collector.userId
        : (widget.users.length == 1 ? widget.users.first.id : null);
    _assignedAreaId =
        collector != null && areaIds.contains(collector.assignedAreaId)
        ? collector.assignedAreaId
        : null;
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      AdminCollectorProfileDraft(
        userId: _userId ?? 0,
        assignedAreaId: _assignedAreaId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collector = widget.collector;

    return AlertDialog(
      title: Text(_isEdit ? 'Uredi profil inkasanta' : 'Dodaj inkasanta'),
      content: SizedBox(
        width: math.min(520, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (collector == null) ...[
                  const _GeneratedCodeInfo(),
                  const SizedBox(height: 14),
                ] else ...[
                  TextFormField(
                    key: ValueKey(collector.employeeCode),
                    initialValue: collector.employeeCode,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Šifra inkasanta',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _userId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Korisnik',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Odaberite korisnika'),
                    ),
                    for (final user in widget.users)
                      DropdownMenuItem(
                        value: user.id,
                        child: Text(_userLabel(user)),
                      ),
                  ],
                  validator: (value) =>
                      value == null || value == 0 ? 'Obavezno polje.' : null,
                  onChanged: (value) {
                    if (value == null || value == 0) {
                      setState(() => _userId = null);
                      return;
                    }
                    setState(() => _userId = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _assignedAreaId ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Područje',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Bez dodijeljenog područja'),
                    ),
                    for (final settlement in widget.settlements)
                      DropdownMenuItem(
                        value: settlement.id,
                        child: Text(settlement.label),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _assignedAreaId = value == 0 ? null : value);
                  },
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

  String _userLabel(AdminUser user) {
    final name = user.fullName.trim();
    final primary = name.isEmpty ? user.email : name;
    final secondary = name.isEmpty || user.email.isEmpty
        ? ''
        : ' - ${user.email}';
    final status = user.isActive ? '' : ' (neaktivan)';
    return '$primary$secondary$status';
  }
}

class _GeneratedCodeInfo extends StatelessWidget {
  const _GeneratedCodeInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Šifra inkasanta se automatski kreira nakon spremanja, npr. COL-0002.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}
