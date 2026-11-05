import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/lookup_item.dart';
import 'package:aquaflow_desktop/services/admin_lookup_exception.dart';
import 'package:aquaflow_desktop/services/admin_lookup_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class _Codebook {
  const _Codebook(this.route, this.icon, this.label);

  final String route;
  final IconData icon;
  final String Function(AppLocalizations loc) label;
}

final List<_Codebook> _codebooks = [
  _Codebook(
    'InvoiceStatuses',
    Icons.receipt_long_outlined,
    (l) => l.lookupInvoiceStatuses,
  ),
  _Codebook(
    'PaymentStatuses',
    Icons.payments_outlined,
    (l) => l.lookupPaymentStatuses,
  ),
  _Codebook(
    'PaymentMethods',
    Icons.credit_card_outlined,
    (l) => l.lookupPaymentMethods,
  ),
  _Codebook(
    'FaultReportStatuses',
    Icons.report_problem_outlined,
    (l) => l.lookupFaultReportStatuses,
  ),
  _Codebook(
    'WaterMeterRequestStatuses',
    Icons.assignment_outlined,
    (l) => l.lookupWaterMeterRequestStatuses,
  ),
  _Codebook(
    'WaterMeterStatuses',
    Icons.speed_outlined,
    (l) => l.lookupWaterMeterStatuses,
  ),
  _Codebook(
    'SupportTicketStatuses',
    Icons.support_agent_outlined,
    (l) => l.lookupSupportTicketStatuses,
  ),
  _Codebook(
    'NotificationTypes',
    Icons.notifications_outlined,
    (l) => l.lookupNotificationTypes,
  ),
  _Codebook(
    'ConsumptionAlertTypes',
    Icons.warning_amber_outlined,
    (l) => l.lookupConsumptionAlertTypes,
  ),
];

class AdminStatusCodebooksScreen extends StatefulWidget {
  const AdminStatusCodebooksScreen({super.key});

  @override
  State<AdminStatusCodebooksScreen> createState() =>
      _AdminStatusCodebooksScreenState();
}

class _AdminStatusCodebooksScreenState extends State<AdminStatusCodebooksScreen>
    with PagedListController<LookupItem, AdminStatusCodebooksScreen> {
  final AdminLookupService _service = AdminLookupService();

  int _selected = 0;

  String get _route => _codebooks[_selected].route;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<LookupItem> items, int totalCount})> fetchPage() async {
    final data = await _service.fetchPage(
      _route,
      name: searchController.text,
      page: page,
      pageSize: pageSize,
    );
    return (items: data.items, totalCount: data.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminLookupException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    searchController.clear();
    load(resetPage: true);
  }

  Future<void> _openCreate() async {
    final route = _route;
    final draft = await showDialog<LookupItemDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LookupEditorDialog(),
    );
    if (!mounted || draft == null) return;
    await runMutation(() async {
      await _service.create(route, draft);
    }, AppLocalizations.of(context).lookupItemCreatedSuccess);
  }

  Future<void> _openEdit(LookupItem item) async {
    final route = _route;
    final draft = await showDialog<LookupItemDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LookupEditorDialog(item: item),
    );
    if (!mounted || draft == null) return;
    await runMutation(() async {
      await _service.update(route, item.id, draft);
    }, AppLocalizations.of(context).lookupItemSavedSuccess);
  }

  Future<void> _confirmDelete(LookupItem item) async {
    final loc = AppLocalizations.of(context);
    final route = _route;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.commonDelete),
        content: Text(loc.deleteLookupItemDialogContent(item.name)),
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
      await _service.delete(route, item.id);
      if (items.length == 1 && page > 1) page -= 1;
    }, loc.lookupItemDeletedSuccess);
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 250,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 24, 0, 12),
              children: [
                for (var i = 0; i < _codebooks.length; i++)
                  ListTile(
                    dense: true,
                    selected: i == _selected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(_codebooks[i].icon),
                    title: Text(_codebooks[i].label(loc)),
                    onTap: loading || mutating ? null : () => _select(i),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildRight(loc)),
        ],
      ),
    );
  }

  Widget _buildRight(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: _codebooks[_selected].label(loc),
                subtitle: loc.statusCodebooksScreenSubtitle,
                actions: [
                  RefreshButton(onRefresh: () => load(), enabled: !mutating),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: loading || mutating ? null : _openCreate,
                    icon: const Icon(Icons.add),
                    label: Text(loc.newLookupItemButton),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                    suffixIcon: searchController.text.trim().isNotEmpty
                        ? IconButton(
                            tooltip: loc.clearSearchTooltip,
                            onPressed: clearSearch,
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
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
        icon: Icons.list_alt_outlined,
        message: loc.noLookupItemsMessage,
        hasFilters: searchController.text.trim().isNotEmpty,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.lookupItemsEmptyFilteredMessage,
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
                    columns: [
                      DataColumn(label: Text(loc.codeColumnLabel)),
                      DataColumn(label: Text(loc.nameColumnLabel)),
                      DataColumn(label: Text(loc.lookupNameEnColumn)),
                      DataColumn(label: Text(loc.lookupNameDeColumn)),
                      DataColumn(label: Text(loc.lookupSortOrderLabel)),
                      DataColumn(label: Text(loc.lookupSystemColumn)),
                      DataColumn(label: Text(loc.lookupActiveColumn)),
                      DataColumn(label: Text(loc.actionsColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(Text(item.code)),
                            DataCell(Text(item.name)),
                            DataCell(Text(item.nameEn ?? '')),
                            DataCell(Text(item.nameDe ?? '')),
                            DataCell(Text('${item.sortOrder}')),
                            DataCell(
                              Icon(
                                item.isSystem
                                    ? Icons.lock_outline
                                    : Icons.remove,
                                size: 18,
                              ),
                            ),
                            DataCell(
                              Icon(
                                item.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined,
                                size: 18,
                                color: item.isActive
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                onEdit: () => _openEdit(item),
                                onDelete: item.isSystem
                                    ? null
                                    : () => _confirmDelete(item),
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

class _LookupEditorDialog extends StatefulWidget {
  const _LookupEditorDialog({this.item});

  final LookupItem? item;

  @override
  State<_LookupEditorDialog> createState() => _LookupEditorDialogState();
}

class _LookupEditorDialogState extends State<_LookupEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _nameDeCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  late bool _isActive;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeCtrl.text = item?.code ?? '';
    _nameCtrl.text = item?.name ?? '';
    _nameEnCtrl.text = item?.nameEn ?? '';
    _nameDeCtrl.text = item?.nameDe ?? '';
    _sortCtrl.text = '${item?.sortOrder ?? 0}';
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _nameEnCtrl.dispose();
    _nameDeCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    Navigator.of(context).pop(
      LookupItemDraft(
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        nameDe: _nameDeCtrl.text.trim(),
        sortOrder: int.tryParse(_sortCtrl.text.trim()) ?? 0,
        isActive: _isActive,
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? AppLocalizations.of(context).fieldRequiredError
      : null;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isSystem = widget.item?.isSystem ?? false;
    return AlertDialog(
      title: Text(_isEdit ? loc.editLookupItemTitle : loc.newLookupItemTitle),
      content: SizedBox(
        width: math.min(520, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeCtrl,
                  readOnly: _isEdit,
                  enabled: !_isEdit,
                  maxLength: 50,
                  validator: _required,
                  decoration: InputDecoration(
                    labelText: loc.codeColumnLabel,
                    prefixIcon: const Icon(Icons.tag),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  maxLength: 100,
                  validator: _required,
                  decoration: InputDecoration(
                    labelText: loc.nameColumnLabel,
                    prefixIcon: const Icon(Icons.label_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameEnCtrl,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: loc.lookupNameEnColumn,
                    prefixIcon: const Icon(Icons.translate),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameDeCtrl,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: loc.lookupNameDeColumn,
                    prefixIcon: const Icon(Icons.translate),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sortCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _required,
                  decoration: InputDecoration(
                    labelText: loc.lookupSortOrderLabel,
                    prefixIcon: const Icon(Icons.sort),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.lookupActiveColumn),
                  value: _isActive,
                  onChanged: isSystem
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
