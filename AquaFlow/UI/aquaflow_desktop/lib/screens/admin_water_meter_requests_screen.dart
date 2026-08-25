import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/models/admin_water_meter_request.dart';
import 'package:aquaflow_desktop/services/admin_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/services/admin_water_meter_request_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminWaterMeterRequestsScreen extends StatefulWidget {
  const AdminWaterMeterRequestsScreen({super.key});

  @override
  State<AdminWaterMeterRequestsScreen> createState() =>
      _AdminWaterMeterRequestsScreenState();
}

class _AdminWaterMeterRequestsScreenState
    extends State<AdminWaterMeterRequestsScreen>
    with
        PagedListController<
          AdminWaterMeterRequest,
          AdminWaterMeterRequestsScreen
        > {
  final AdminWaterMeterRequestService _service =
      AdminWaterMeterRequestService();

  List<AdminCollectorProfile> _collectors = const [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminWaterMeterRequest> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      status: _statusFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminWaterMeterRequestException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  Future<bool> _loadCollectors() async {
    try {
      final collectors = await _service.fetchCollectors();
      if (!mounted) return false;
      setState(() => _collectors = collectors);
      return true;
    } catch (e) {
      if (!mounted) return false;
      showError(describeError(e));
      return false;
    }
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    load(resetPage: true);
  }

  Future<void> _openAssign(AdminWaterMeterRequest request) async {
    final loaded = await _loadCollectors();
    if (!mounted || !loaded) return;

    if (_collectors.isEmpty) {
      showError(AppLocalizations.of(context).noCollectorsAvailableError);
      return;
    }

    final collectorId = await showDialog<int>(
      context: context,
      builder: (_) => _AssignDialog(collectors: _collectors),
    );
    if (!mounted || collectorId == null) return;

    await runMutation(() async {
      await _service.assign(request.id, collectorId);
    }, AppLocalizations.of(context).requestAssignedSuccess);
  }

  Future<void> _openReject(AdminWaterMeterRequest request) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (!mounted || reason == null) return;

    await runMutation(() async {
      await _service.reject(request.id, reason);
    }, AppLocalizations.of(context).requestRejectedSuccess);
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
                  title: loc.waterMeterRequestsPageTitle,
                  subtitle: loc.waterMeterRequestsPageSubtitle,
                  actions: [
                    RefreshButton(onRefresh: () => load(), enabled: !mutating),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            decoration: InputDecoration(
              labelText: loc.statusFieldLabel,
              prefixIcon: const Icon(Icons.filter_alt_outlined),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(loc.allStatusesOption)),
              DropdownMenuItem(
                value: 'Pending',
                child: Text(loc.requestStatusPending),
              ),
              DropdownMenuItem(
                value: 'Assigned',
                child: Text(loc.requestStatusAwaitingRegistration),
              ),
              DropdownMenuItem(
                value: 'Registered',
                child: Text(loc.requestStatusRegistered),
              ),
              DropdownMenuItem(
                value: 'Rejected',
                child: Text(loc.requestStatusRejected),
              ),
              DropdownMenuItem(
                value: 'Cancelled',
                child: Text(loc.requestStatusCancelled),
              ),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: loc.applyFilterTooltip,
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
        icon: Icons.assignment_outlined,
        message: loc.noWaterMeterRequestsMessage,
        hasFilters: _statusFilter != null,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.waterMeterRequestsEmptyFilteredMessage,
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
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 88,
                    columns: [
                      DataColumn(label: Text(loc.addressLabel)),
                      DataColumn(label: Text(loc.customerColumnLabel)),
                      DataColumn(label: Text(loc.statusFieldLabel)),
                      DataColumn(label: Text(loc.collectorColumnLabel)),
                      DataColumn(label: Text(loc.createdColumnLabel)),
                      DataColumn(label: Text(loc.actionsColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(_RequestCell(request: item)),
                            DataCell(_CustomerCell(request: item)),
                            DataCell(_RequestStatusPill(status: item.status)),
                            DataCell(
                              Text(_collectorLabel(item.assignedCollectorId)),
                            ),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _RowActions(
                                request: item,
                                disabled: mutating,
                                onAssign: () => _openAssign(item),
                                onReject: () => _openReject(item),
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

  String _collectorLabel(int? collectorId) {
    if (collectorId == null) return '-';
    for (final collector in _collectors) {
      if (collector.id == collectorId) return collector.label;
    }
    return AppLocalizations.of(context).collectorFallbackLabel(collectorId);
  }
}

class _RequestCell extends StatelessWidget {
  const _RequestCell({required this.request});

  final AdminWaterMeterRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settlement = request.settlementName.trim();
    final address = request.address;
    final note = request.note?.trim();

    return SizedBox(
      width: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settlement.isEmpty ? loc.unknownSettlementLabel : settlement,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            address.isEmpty ? loc.noStreetAddressLabel : address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.request});

  final AdminWaterMeterRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final name = request.customerFullName;
    final phone = request.customerPhone?.trim();

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty
                ? loc.requestCustomerFallbackLabel(request.customerId)
                : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phone == null || phone.isEmpty ? loc.noPhoneLabel : phone,
            maxLines: 1,
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

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.request,
    required this.disabled,
    required this.onAssign,
    required this.onReject,
  });

  final AdminWaterMeterRequest request;
  final bool disabled;
  final VoidCallback onAssign;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!request.isPending) {
      final text = request.isAssigned
          ? loc.requestStatusAwaitingRegistration
          : '-';
      return Text(text);
    }

    return TableRowActions(
      disabled: disabled,
      extraActions: [
        IconButton(
          tooltip: loc.assignToCollectorTooltip,
          onPressed: disabled ? null : onAssign,
          icon: const Icon(Icons.assignment_ind_outlined),
        ),
        IconButton(
          tooltip: loc.rejectTooltip,
          onPressed: disabled ? null : onReject,
          icon: const Icon(Icons.block_outlined),
        ),
      ],
    );
  }
}

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.collectors});

  final List<AdminCollectorProfile> collectors;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  int? _collectorId;

  @override
  void initState() {
    super.initState();
    _collectorId = widget.collectors.length == 1
        ? widget.collectors.first.id
        : null;
  }

  void _selectCollector(AdminCollectorProfile collector) {
    setState(() => _collectorId = collector.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc.assignToCollectorTooltip),
      content: SizedBox(
        width: 820,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 44,
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 66,
                      columns: [
                        DataColumn(label: Text(loc.selectionColumnLabel)),
                        DataColumn(label: Text(loc.fullNameColumnLabel)),
                        DataColumn(label: Text(loc.fieldEmailLabel)),
                        DataColumn(label: Text(loc.fieldPhoneLabel)),
                      ],
                      rows: [
                        for (final collector in widget.collectors)
                          _buildCollectorRow(context, collector),
                      ],
                    ),
                  ),
                ),
              ),
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
          onPressed: _collectorId == null
              ? null
              : () => Navigator.of(context).pop(_collectorId),
          icon: const Icon(Icons.assignment_ind_outlined),
          label: Text(loc.assignButtonLabel),
        ),
      ],
    );
  }

  DataRow _buildCollectorRow(
    BuildContext context,
    AdminCollectorProfile collector,
  ) {
    final theme = Theme.of(context);
    final selected = collector.id == _collectorId;
    final iconColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return DataRow(
      selected: selected,
      onSelectChanged: (_) => _selectCollector(collector),
      cells: [
        DataCell(
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: iconColor,
            size: 20,
          ),
        ),
        DataCell(
          SizedBox(
            width: 230,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profileLabel(collector),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              _textOrDash(collector.email),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              _textOrDash(collector.phone),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _profileLabel(AdminCollectorProfile collector) {
    final code = collector.employeeCode.trim();
    if (code.isNotEmpty) return code;
    return AppLocalizations.of(
      context,
    ).collectorProfileFallbackLabel(collector.id);
  }

  String _textOrDash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.rejectRequestDialogTitle),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _reasonCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: loc.reasonOptionalLabel,
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.notes_outlined),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.dialogDismissButton),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_reasonCtrl.text),
          icon: const Icon(Icons.block_outlined),
          label: Text(loc.rejectTooltip),
        ),
      ],
    );
  }
}

class _RequestStatusPill extends StatelessWidget {
  const _RequestStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final (label, color, icon) = switch (status.toLowerCase()) {
      'pending' => (
        loc.requestStatusPending,
        const Color(0xFFB45309),
        Icons.hourglass_top_outlined,
      ),
      'assigned' => (
        loc.requestStatusAwaitingRegistration,
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'registered' => (
        loc.requestStatusRegistered,
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      'rejected' => (
        loc.requestStatusRejected,
        const Color(0xFFB91C1C),
        Icons.block_outlined,
      ),
      'cancelled' => (
        loc.requestStatusCancelled,
        const Color(0xFF64748B),
        Icons.cancel_outlined,
      ),
      _ => (
        status.isEmpty ? '-' : status,
        const Color(0xFF64748B),
        Icons.help_outline,
      ),
    };

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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
