import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/models/admin_notification_draft.dart';
import 'package:aquaflow_desktop/admin/services/admin_notification_service.dart';
import 'package:aquaflow_desktop/shared/models/app_notification.dart';
import 'package:aquaflow_desktop/shared/models/app_notification_page.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/services/notification_exception.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminNotificationService _service = AdminNotificationService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _settlementFilterCtrl = TextEditingController();

  Timer? _searchDebounce;
  AppNotificationPage? _pageData;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  String? _typeFilter;
  String? _audienceFilter;
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
    final settlementId = _settlementFilterId;

    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetch(
        page: _page,
        pageSize: _pageSize,
        search: _searchCtrl.text,
        type: _typeFilter,
        audience: _audienceFilter,
        settlementId: settlementId,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on NotificationException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  int? get _settlementFilterId {
    final text = _settlementFilterCtrl.text.trim();
    if (text.isEmpty) return null;
    final id = int.tryParse(text);
    return id == null || id <= 0 ? null : id;
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

  void _setTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _typeFilter) return;
    setState(() => _typeFilter = selected);
    _load(resetPage: true);
  }

  void _setAudienceFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _audienceFilter) return;
    setState(() => _audienceFilter = selected);
    _load(resetPage: true);
  }

  void _applySettlementFilter(String _) {
    _load(resetPage: true);
  }

  void _clearSettlementFilter() {
    if (_settlementFilterCtrl.text.isEmpty) return;
    _settlementFilterCtrl.clear();
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
    final createdById = context.read<AuthProvider>().session?.id;
    if (createdById == null || createdById <= 0) {
      _showError('Nije moguće odrediti admin korisnika.');
      return;
    }

    final draft = await showDialog<AdminNotificationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationEditorDialog(createdById: createdById),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.create(draft);
    }, 'Obavijest je dodana.');
  }

  Future<void> _openEdit(AppNotification notification) async {
    final sessionUserId = context.read<AuthProvider>().session?.id;
    final createdById = notification.createdById > 0
        ? notification.createdById
        : sessionUserId;
    if (createdById == null || createdById <= 0) {
      _showError('Nije moguće odrediti autora obavijesti.');
      return;
    }

    final draft = await showDialog<AdminNotificationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationEditorDialog(
        notification: notification,
        createdById: createdById,
      ),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.update(notification.id, draft);
    }, 'Obavijest je sačuvana.');
  }

  Future<void> _confirmDelete(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši obavijest'),
        content: Text(
          'Da li želite obrisati obavijest "${notification.title}"? '
          'Povezani zapisi korisničkih obavijesti će također biti uklonjeni.',
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
      await _service.delete(notification.id);
      if ((_pageData?.items.length ?? 0) == 1 && _page > 1) {
        _page -= 1;
      }
    }, 'Obavijest je obrisana.');
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
    } on NotificationException catch (e) {
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
    _settlementFilterCtrl.dispose();
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
    final hasSettlement = _settlementFilterCtrl.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _queueSearch,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Pretraga',
              hintText: 'Naslov, sadržaj, tip ili publika',
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
          width: 210,
          child: DropdownButtonFormField<String>(
            initialValue: _typeFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Tip',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi tipovi')),
              for (final option in _notificationTypeOptions)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setTypeFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _audienceFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Publika',
              prefixIcon: Icon(Icons.group_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Sve publike')),
              for (final option in _audienceOptions)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: _loading || _mutating
                ? null
                : (value) => _setAudienceFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _settlementFilterCtrl,
            enabled: !_loading && !_mutating,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: _applySettlementFilter,
            decoration: InputDecoration(
              labelText: 'ID naselja',
              prefixIcon: const Icon(Icons.location_city_outlined),
              suffixIcon: hasSettlement
                  ? IconButton(
                      tooltip: 'Očisti filter naselja',
                      onPressed: _clearSettlementFilter,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
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

    final items = _pageData?.items ?? const <AppNotification>[];
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
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 84,
                    columns: const [
                      DataColumn(label: Text('Obavijest')),
                      DataColumn(label: Text('Tip')),
                      DataColumn(label: Text('Publika')),
                      DataColumn(label: Text('Naselje')),
                      DataColumn(label: Text('Važi do')),
                      DataColumn(label: Text('Kreirano')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(_NotificationTitleCell(item: item)),
                            DataCell(
                              _InfoPill(
                                icon: _typeIcon(item.type),
                                label: _typeLabel(item.type),
                                color: _typeColor(
                                  item.type,
                                  Theme.of(context).colorScheme,
                                ),
                              ),
                            ),
                            DataCell(Text(_audienceLabel(item.audience))),
                            DataCell(
                              Text(item.settlementId?.toString() ?? '-'),
                            ),
                            DataCell(Text(_formatDate(item.validUntil))),
                            DataCell(Text(_formatDate(item.createdAt))),
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
      _typeFilter != null ||
      _audienceFilter != null ||
      _settlementFilterCtrl.text.trim().isNotEmpty;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).ceil();
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
          'Obavijesti',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled, dodavanje, uređivanje i brisanje sistemskih obavijesti.',
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
          label: const Text('Nova obavijest'),
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

class _NotificationTitleCell extends StatelessWidget {
  const _NotificationTitleCell({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.title.trim().isEmpty
        ? 'Obavijest #${item.id}'
        : item.title.trim();

    return SizedBox(
      width: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
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

class _NotificationEditorDialog extends StatefulWidget {
  const _NotificationEditorDialog({
    required this.createdById,
    this.notification,
  });

  final int createdById;
  final AppNotification? notification;

  @override
  State<_NotificationEditorDialog> createState() =>
      _NotificationEditorDialogState();
}

class _NotificationEditorDialogState extends State<_NotificationEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _settlementCtrl = TextEditingController();

  late String _type;
  late String _audience;
  DateTime? _validUntil;

  bool get _isEdit => widget.notification != null;

  @override
  void initState() {
    super.initState();
    final notification = widget.notification;
    _titleCtrl.text = notification?.title ?? '';
    _bodyCtrl.text = notification?.body ?? '';
    _settlementCtrl.text = notification?.settlementId?.toString() ?? '';
    _type = notification?.type.trim().isNotEmpty == true
        ? notification!.type
        : 'Info';
    _audience = notification?.audience.trim().isNotEmpty == true
        ? notification!.audience
        : 'All';
    _validUntil = notification?.validUntil;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _settlementCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickValidUntil() async {
    final now = DateTime.now();
    final initial = _validUntil ?? now.add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;

    setState(() {
      _validUntil = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final settlementId = _audience.toLowerCase() == 'settlement'
        ? int.tryParse(_settlementCtrl.text.trim())
        : null;

    Navigator.of(context).pop(
      AdminNotificationDraft(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        type: _type,
        audience: _audience,
        settlementId: settlementId,
        createdById: widget.createdById,
        validUntil: _validUntil,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeOptions = _optionsWithCurrent(_notificationTypeOptions, _type);
    final audienceOptions = _optionsWithCurrent(_audienceOptions, _audience);
    final isSettlementAudience = _audience.toLowerCase() == 'settlement';

    return AlertDialog(
      title: Text(_isEdit ? 'Uredi obavijest' : 'Nova obavijest'),
      content: SizedBox(
        width: math.min(640, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Naslov',
                    prefixIcon: Icon(Icons.title),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bodyCtrl,
                  minLines: 4,
                  maxLines: 7,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Sadržaj',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tip',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          for (final option in typeOptions)
                            DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _type = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _audience,
                        decoration: const InputDecoration(
                          labelText: 'Publika',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        items: [
                          for (final option in audienceOptions)
                            DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _audience = value;
                            if (value.toLowerCase() != 'settlement') {
                              _settlementCtrl.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _settlementCtrl,
                  enabled: isSettlementAudience,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _settlementValidator,
                  decoration: InputDecoration(
                    labelText: isSettlementAudience
                        ? 'ID naselja'
                        : 'ID naselja (samo za publiku Naselje)',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                _ValidUntilField(
                  value: _validUntil,
                  onPick: _pickValidUntil,
                  onClear: _validUntil == null
                      ? null
                      : () => setState(() => _validUntil = null),
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

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
  }

  String? _settlementValidator(String? value) {
    if (_audience.toLowerCase() != 'settlement') return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Unesite ID naselja.';
    final id = int.tryParse(text);
    if (id == null || id <= 0) return 'Unesite pozitivan broj.';
    return null;
  }
}

class _ValidUntilField extends StatelessWidget {
  const _ValidUntilField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6ED)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Važi do',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null ? 'Nije postavljeno' : _formatDate(value),
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
          IconButton(
            tooltip: 'Ukloni datum',
            onPressed: onClear,
            icon: const Icon(Icons.clear),
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
            hasFilters ? Icons.search_off : Icons.notifications_none,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'Nema obavijesti za zadane filtere.'
                : 'Nema obavijesti.',
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

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<_SelectOption> _notificationTypeOptions = [
  _SelectOption(value: 'Info', label: 'Info'),
  _SelectOption(value: 'PlannedWorks', label: 'Planirani radovi'),
  _SelectOption(value: 'Billing', label: 'Računi'),
  _SelectOption(value: 'Warning', label: 'Upozorenje'),
  _SelectOption(value: 'Outage', label: 'Prekid usluge'),
];

const List<_SelectOption> _audienceOptions = [
  _SelectOption(value: 'All', label: 'Svi korisnici'),
  _SelectOption(value: 'Settlement', label: 'Naselje'),
  _SelectOption(value: 'Customers', label: 'Korisnici'),
  _SelectOption(value: 'Collectors', label: 'Inkasanti'),
];

List<_SelectOption> _optionsWithCurrent(
  List<_SelectOption> options,
  String current,
) {
  final value = current.trim();
  if (value.isEmpty ||
      options.any(
        (option) => option.value.toLowerCase() == value.toLowerCase(),
      )) {
    return options;
  }
  return [...options, _SelectOption(value: value, label: value)];
}

IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return Icons.construction_outlined;
    case 'billing':
      return Icons.receipt_long_outlined;
    case 'warning':
    case 'outage':
      return Icons.warning_amber_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _typeColor(String type, ColorScheme colorScheme) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return const Color(0xFF0277BD);
    case 'billing':
      return const Color(0xFF2E7D32);
    case 'warning':
    case 'outage':
      return const Color(0xFFF9A825);
    default:
      return colorScheme.primary;
  }
}

String _typeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return 'Planirani radovi';
    case 'billing':
      return 'Računi';
    case 'warning':
      return 'Upozorenje';
    case 'outage':
      return 'Prekid usluge';
    default:
      return type.isEmpty ? 'Obavijest' : type;
  }
}

String _audienceLabel(String audience) {
  switch (audience.toLowerCase()) {
    case 'all':
      return 'Svi korisnici';
    case 'settlement':
      return 'Naselje';
    case 'customer':
    case 'customers':
      return 'Korisnici';
    case 'collector':
    case 'collectors':
      return 'Inkasanti';
    default:
      return audience.isEmpty ? 'Publika' : audience;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
