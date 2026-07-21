import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/models/admin_notification_draft.dart';
import 'package:aquaflow_desktop/admin/services/admin_notification_service.dart';
import 'package:aquaflow_desktop/shared/models/app_notification.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/services/notification_exception.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with PagedListController<AppNotification, AdminNotificationsScreen> {
  final AdminNotificationService _service = AdminNotificationService();
  final TextEditingController _settlementFilterCtrl = TextEditingController();

  String? _typeFilter;
  String? _audienceFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AppNotification> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      search: searchController.text,
      type: _typeFilter,
      audience: _audienceFilter,
      settlementId: _settlementFilterId,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is NotificationException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  int? get _settlementFilterId {
    final text = _settlementFilterCtrl.text.trim();
    if (text.isEmpty) return null;
    final id = int.tryParse(text);
    return id == null || id <= 0 ? null : id;
  }

  void _setTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _typeFilter) return;
    setState(() => _typeFilter = selected);
    load(resetPage: true);
  }

  void _setAudienceFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _audienceFilter) return;
    setState(() => _audienceFilter = selected);
    load(resetPage: true);
  }

  void _applySettlementFilter(String _) {
    load(resetPage: true);
  }

  void _clearSettlementFilter() {
    if (_settlementFilterCtrl.text.isEmpty) return;
    _settlementFilterCtrl.clear();
    setState(() {});
    load(resetPage: true);
  }

  Future<void> _openCreate() async {
    final createdById = context.read<AuthProvider>().session?.id;
    if (createdById == null || createdById <= 0) {
      showError('Nije moguće odrediti admin korisnika.');
      return;
    }

    final draft = await showDialog<AdminNotificationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationEditorDialog(createdById: createdById),
    );
    if (!mounted || draft == null) return;

    await runMutation(() async {
      await _service.create(draft);
    }, 'Obavijest je dodana.');
  }

  Future<void> _openEdit(AppNotification notification) async {
    final sessionUserId = context.read<AuthProvider>().session?.id;
    final createdById = notification.createdById > 0
        ? notification.createdById
        : sessionUserId;
    if (createdById == null || createdById <= 0) {
      showError('Nije moguće odrediti autora obavijesti.');
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

    await runMutation(() async {
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

    await runMutation(() async {
      await _service.delete(notification.id);
      if (items.length == 1 && page > 1) {
        page -= 1;
      }
    }, 'Obavijest je obrisana.');
  }

  @override
  void dispose() {
    disposeController();
    _settlementFilterCtrl.dispose();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: 'Obavijesti',
                  subtitle:
                      'Pregled, dodavanje, uređivanje i brisanje sistemskih obavijesti.',
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
                      label: const Text('Nova obavijest'),
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
      ),
    );
  }

  Widget _buildFilters() {
    final hasSearch = searchController.text.trim().isNotEmpty;
    final hasSettlement = _settlementFilterCtrl.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: 'Pretraga',
              hintText: 'Naslov, sadržaj, tip ili publika',
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
            onChanged: loading || mutating
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
            onChanged: loading || mutating
                ? null
                : (value) => _setAudienceFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _settlementFilterCtrl,
            enabled: !loading && !mutating,
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
          onPressed: loading || mutating ? null : () => load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
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
      return EmptyStateView(
        icon: Icons.notifications_none,
        message: 'Nema obavijesti.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema obavijesti za zadane filtere.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;

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
                    columns: [
                      const DataColumn(label: Text('Obavijest')),
                      const DataColumn(label: Text('Tip')),
                      if (!isSmallScreen) const DataColumn(label: Text('Publika')),
                      if (!isSmallScreen) const DataColumn(label: Text('Naselje')),
                      if (!isSmallScreen) const DataColumn(label: Text('Važi do')),
                      if (!isSmallScreen) const DataColumn(label: Text('Kreirano')),
                      const DataColumn(label: Text('Akcije')),
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
                            if (!isSmallScreen)
                              DataCell(Text(_audienceLabel(item.audience))),
                            if (!isSmallScreen)
                              DataCell(
                                Text(item.settlementId?.toString() ?? '-'),
                              ),
                            if (!isSmallScreen)
                              DataCell(Text(_formatDate(item.validUntil))),
                            if (!isSmallScreen)
                              DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
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
      searchController.text.trim().isNotEmpty ||
      _typeFilter != null ||
      _audienceFilter != null ||
      _settlementFilterCtrl.text.trim().isNotEmpty;
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
