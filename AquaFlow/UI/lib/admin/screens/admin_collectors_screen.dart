import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_collector_profile_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_collector_profile_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_option.dart';
import 'package:aquaflow_desktop/admin/models/admin_user.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_collector_service.dart';

class AdminCollectorsScreen extends StatefulWidget {
  const AdminCollectorsScreen({super.key});

  @override
  State<AdminCollectorsScreen> createState() => _AdminCollectorsScreenState();
}

class _AdminCollectorsScreenState extends State<AdminCollectorsScreen> {
  final AdminCollectorService _service = AdminCollectorService();

  AdminCollectorProfilePage? _pageData;
  List<AdminUser> _collectorUsers = const [];
  List<AdminSettlementOption> _settlements = const [];
  bool _loading = true;
  bool _mutating = false;
  bool _lookupsLoading = false;
  String? _error;
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
      final pageData = await _service.fetchCollectors(
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminCollectorException catch (e) {
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
        _service.fetchCollectorUsers(),
        _service.fetchSettlements(),
      ]);
      if (!mounted) return false;
      setState(() {
        _collectorUsers = results[0] as List<AdminUser>;
        _settlements = results[1] as List<AdminSettlementOption>;
      });
      return true;
    } on AdminCollectorException catch (e) {
      if (!mounted) return false;
      if (showErrors) _showError(e.message);
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
    } on AdminCollectorException catch (e) {
      if (!mounted) return false;
      if (showErrors) _showError(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _lookupsLoading = false);
    }
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

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage, {
    bool resetPageAfterSuccess = false,
  }) async {
    setState(() => _mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _load(resetPage: resetPageAfterSuccess);
      await _loadLookups(showErrors: false);
    } on AdminCollectorException catch (e) {
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
            child: _Header(
              loading: _loading || _lookupsLoading,
              mutating: _mutating,
              onRefresh: () {
                _load();
                _loadLookups();
              },
              onCreate: _openCreate,
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

  Widget _buildContent() {
    if (_loading && _pageData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: () => _load());
    }

    final items = _pageData?.items ?? const <AdminCollectorProfile>[];
    if (items.isEmpty) {
      return const _EmptyState();
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
                              _RowActions(
                                disabled: _mutating,
                                onEdit: () => _openEdit(item),
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
          'Inkasanti',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled i uređivanje profila inkasanata za terenski rad.',
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
          label: const Text('Dodaj inkasanta'),
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
  const _RowActions({required this.disabled, required this.onEdit});

  final bool disabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Uredi profil',
      onPressed: disabled ? null : onEdit,
      icon: const Icon(Icons.edit_outlined),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Nema profila inkasanata.',
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
