import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report.dart';
import 'package:aquaflow_desktop/admin/models/admin_fault_report_photo.dart';
import 'package:aquaflow_desktop/admin/services/admin_fault_report_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_fault_report_service.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

/// Desktop admin table over `/FaultReports` (`AdminFaultReportService`/
/// `AdminFaultReport` data layer), using the shared `PagedListController`
/// mixin for paging/debounce/mutation (see `AdminTariffsScreen`). Row click
/// opens a detail dialog with the full description and a photo gallery; row
/// actions assign a collector (`POST {id}/assign`, pick-list from
/// `/CollectorProfiles` - mirrors `AdminWaterMeterRequestsScreen`'s assign
/// dialog, plus an optional note that lands in `FaultStatusHistory`) and
/// advance the status (New/Assigned -> InProgress -> Resolved, via the
/// backend transition endpoints `POST {id}/start`/`{id}/resolve` - the server
/// stamps `resolvedAt` itself).
class AdminFaultReportsScreen extends StatefulWidget {
  const AdminFaultReportsScreen({super.key});

  @override
  State<AdminFaultReportsScreen> createState() =>
      _AdminFaultReportsScreenState();
}

const _statusOptions = <String, String>{
  'New': 'Nova',
  'Assigned': 'Dodijeljena',
  'InProgress': 'U toku',
  'Resolved': 'Riješena',
};

class _AdminFaultReportsScreenState extends State<AdminFaultReportsScreen>
    with PagedListController<AdminFaultReport, AdminFaultReportsScreen> {
  final AdminFaultReportService _service = AdminFaultReportService();

  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminFaultReport> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      term: searchController.text,
      status: _statusFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminFaultReportException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    load(resetPage: true);
  }

  void _openDetail(AdminFaultReport report) {
    showDialog<void>(
      context: context,
      builder: (_) => _FaultReportDetailDialog(report: report, service: _service),
    );
  }

  Future<void> _advanceStatus(AdminFaultReport report) async {
    final next = _nextStatus(report.status);
    if (next == null) return;

    final confirmed = await _confirmAction(
      title: 'Promijeni status',
      message:
          'Da li želite promijeniti status prijave "${report.title}" u '
          '"${_statusOptions[next] ?? next}"?',
      confirmLabel: 'Promijeni',
      icon: _statusIcon(next),
    );
    if (!mounted || confirmed != true) return;

    // New/Assigned -> start, InProgress -> resolve; the backend state machine
    // stamps resolvedAt itself, so no date is sent from here anymore.
    await runMutation(() async {
      if (report.status == 'New' || report.status == 'Assigned') {
        await _service.start(report.id);
      } else {
        await _service.resolve(report.id);
      }
    }, 'Status prijave je promijenjen.');
  }

  /// Assign (or reassign) the report to a collector: pick-list from
  /// `/CollectorProfiles` plus an optional note, mirroring
  /// `AdminWaterMeterRequestsScreen._openAssign`.
  Future<void> _openAssign(AdminFaultReport report) async {
    final List<AdminCollectorProfile> collectors;
    try {
      collectors = await _service.fetchCollectors();
    } catch (e) {
      if (!mounted) return;
      showError(describeError(e));
      return;
    }
    if (!mounted) return;

    if (collectors.isEmpty) {
      showError('Nema dostupnih inkasanata.');
      return;
    }

    final result = await showDialog<({int collectorId, String? note})>(
      context: context,
      builder: (_) => _AssignDialog(
        collectors: collectors,
        currentCollectorId: report.assignedCollectorId,
      ),
    );
    if (!mounted || result == null) return;

    await runMutation(() async {
      await _service.assign(
        report.id,
        collectorId: result.collectorId,
        note: result.note,
      );
    }, 'Prijava je dodijeljena inkasantu.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(icon),
            label: Text(confirmLabel),
          ),
        ],
      ),
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
                  title: 'Prijave kvarova',
                  subtitle: 'Pregled prijava kvarova i upravljanje statusom.',
                  actions: [
                    IconButton(
                      tooltip: 'Osvježi',
                      onPressed: loading || mutating ? null : () => load(),
                      icon: const Icon(Icons.refresh),
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

    return Wrap(
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
              labelText: 'Naslov, kupac ili naselje',
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
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final entry in _statusOptions.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
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
        icon: Icons.report_problem_outlined,
        message: 'Nema prijava kvarova.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema prijava kvarova za zadane filtere.',
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
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
                    columns: const [
                      DataColumn(label: Text('Naslov')),
                      DataColumn(label: Text('Kupac')),
                      DataColumn(label: Text('Adresa')),
                      DataColumn(label: Text('Inkasant')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Datum')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openDetail(item),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  item.title.isEmpty ? '-' : item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Empty when the reporter has no CustomerProfile
                            // (CustomerId is null - ownership is ReportedById).
                            DataCell(Text(
                              item.customerFullName.isEmpty
                                  ? '-'
                                  : item.customerFullName,
                            )),
                            DataCell(Text(_reportLocationLabel(item))),
                            DataCell(Text(_collectorLabel(item))),
                            DataCell(_StatusPill(status: item.status)),
                            DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              _RowActions(
                                report: item,
                                disabled: mutating,
                                onAssign: () => _openAssign(item),
                                onAdvanceStatus: () => _advanceStatus(item),
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
      searchController.text.trim().isNotEmpty || _statusFilter != null;
}

String? _nextStatus(String status) {
  switch (status) {
    case 'New':
    case 'Assigned':
      return 'InProgress';
    case 'InProgress':
      return 'Resolved';
    default:
      return null;
  }
}

/// Assign is offered while the state machine allows it: New (first assignment)
/// and Assigned (reassignment to another collector).
bool _canAssign(String status) => status == 'New' || status == 'Assigned';

/// Table/detail label for the report's own location: "Naselje, Ulica Broj"
/// (address part omitted when the report carries no street/house number).
String _reportLocationLabel(AdminFaultReport report) {
  final parts = [
    report.settlementName.trim(),
    report.address,
  ].where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? '-' : parts.join(', ');
}

/// Table/detail label for the assigned collector: the flattened employee code,
/// a `#id` fallback when the code is missing, or '-' while unassigned.
String _collectorLabel(AdminFaultReport report) {
  final collectorId = report.assignedCollectorId;
  if (collectorId == null) return '-';
  final code = report.assignedCollectorEmployeeCode?.trim() ?? '';
  return code.isEmpty ? 'Inkasant #$collectorId' : code;
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'InProgress':
      return Icons.engineering_outlined;
    case 'Resolved':
      return Icons.check_circle_outline;
    default:
      return Icons.fiber_new_outlined;
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.report,
    required this.disabled,
    required this.onAssign,
    required this.onAdvanceStatus,
  });

  final AdminFaultReport report;
  final bool disabled;
  final VoidCallback onAssign;
  final VoidCallback onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(report.status);
    final canAssign = _canAssign(report.status);

    return TableRowActions(
      disabled: disabled,
      extraActions: [
        IconButton(
          tooltip: canAssign
              ? (report.assignedCollectorId == null
                    ? 'Dodijeli inkasantu'
                    : 'Preraspodijeli drugom inkasantu')
              : 'Dodjela više nije moguća',
          onPressed: disabled || !canAssign ? null : onAssign,
          icon: const Icon(Icons.assignment_ind_outlined),
        ),
        IconButton(
          tooltip: next == null
              ? 'Prijava je riješena'
              : 'Promijeni status u "${_statusOptions[next] ?? next}"',
          onPressed: disabled || next == null ? null : onAdvanceStatus,
          icon: Icon(_statusIcon(next ?? report.status)),
        ),
      ],
    );
  }
}

/// Coloured status pill: New=slate, Assigned=blue, InProgress=amber,
/// Resolved=green - same color token pattern as `_InvoiceStatusPill`.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'New' => ('Nova', const Color(0xFF64748B), Icons.fiber_new_outlined),
      'Assigned' => (
        'Dodijeljena',
        const Color(0xFF1D4ED8),
        Icons.assignment_ind_outlined,
      ),
      'InProgress' => (
        'U toku',
        const Color(0xFFB45309),
        Icons.engineering_outlined,
      ),
      'Resolved' => (
        'Riješena',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      _ => (status, const Color(0xFF64748B), Icons.help_outline),
    };

    return _Pill(label: label, color: color, icon: icon);
  }
}

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

/// Collector pick-list for assigning a fault report, mirroring
/// `AdminWaterMeterRequestsScreen._AssignDialog` plus an optional "Napomena"
/// field whose text lands in the backend's `FaultStatusHistory` note. Returns
/// a `(collectorId, note)` record via `Navigator.pop`. The report's current
/// collector (reassignment case) is pre-selected.
class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.collectors, this.currentCollectorId});

  final List<AdminCollectorProfile> collectors;
  final int? currentCollectorId;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  int? _collectorId;

  @override
  void initState() {
    super.initState();
    final current = widget.currentCollectorId;
    if (current != null &&
        widget.collectors.any((collector) => collector.id == current)) {
      _collectorId = current;
    } else if (widget.collectors.length == 1) {
      _collectorId = widget.collectors.first.id;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _selectCollector(AdminCollectorProfile collector) {
    setState(() => _collectorId = collector.id);
  }

  void _submit() {
    final collectorId = _collectorId;
    if (collectorId == null) return;
    final note = _noteCtrl.text.trim();
    Navigator.of(
      context,
    ).pop((collectorId: collectorId, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Dodijeli inkasantu'),
      content: SizedBox(
        width: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
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
                          columns: const [
                            DataColumn(label: Text('Izbor')),
                            DataColumn(label: Text('Ime i prezime')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Telefon')),
                            DataColumn(label: Text('Područje')),
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
            const SizedBox(height: 14),
            TextField(
              controller: _noteCtrl,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Napomena (opcionalno)',
                hintText: 'Razlog dodjele ili uputa inkasantu',
                border: OutlineInputBorder(),
              ),
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
          onPressed: _collectorId == null ? null : _submit,
          icon: const Icon(Icons.assignment_ind_outlined),
          label: const Text('Dodijeli'),
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
        DataCell(Text(collector.areaLabel)),
      ],
    );
  }

  String _profileLabel(AdminCollectorProfile collector) {
    final code = collector.employeeCode.trim();
    if (code.isNotEmpty) return code;
    return 'Profil #${collector.id}';
  }

  String _textOrDash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}

/// Full detail view of a fault report, opened from a row click. Fetches the
/// photo gallery lazily (`GET /FaultReports/{id}/photos`) and renders each
/// thumbnail through the shared `AuthenticatedImage` widget; tapping one opens
/// a fullscreen preview, same pattern as `CustomerFaultReportDetailScreen`.
class _FaultReportDetailDialog extends StatefulWidget {
  const _FaultReportDetailDialog({required this.report, required this.service});

  final AdminFaultReport report;
  final AdminFaultReportService service;

  @override
  State<_FaultReportDetailDialog> createState() =>
      _FaultReportDetailDialogState();
}

class _FaultReportDetailDialogState extends State<_FaultReportDetailDialog> {
  bool _loading = true;
  String? _error;
  List<AdminFaultReportPhoto> _photos = const [];

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
      final photos = await widget.service.fetchPhotos(widget.report.id);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } on AdminFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _openFullscreen(AdminFaultReportPhoto photo) {
    context.pushScreen(
      _FullscreenPhotoScreen(
        fileName: photo.fileName,
        fetcher: () =>
            widget.service.fetchPhotoBytes(widget.report.id, photo.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(report.title.isEmpty ? '-' : report.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusPill(status: report.status),
              const SizedBox(height: 14),
              _KeyValueRow(
                label: 'Kupac',
                value: report.customerFullName.isEmpty
                    ? '-'
                    : report.customerFullName,
              ),
              const SizedBox(height: 6),
              _KeyValueRow(label: 'Adresa', value: _reportLocationLabel(report)),
              const SizedBox(height: 6),
              _KeyValueRow(label: 'Inkasant', value: _collectorLabel(report)),
              const SizedBox(height: 6),
              _KeyValueRow(
                label: 'Prijavljeno',
                value: _formatDateTime(report.createdAt),
              ),
              if (report.resolvedAt != null) ...[
                const SizedBox(height: 6),
                _KeyValueRow(
                  label: 'Riješeno',
                  value: _formatDateTime(report.resolvedAt),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Opis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                report.description.isEmpty ? '-' : report.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                'Fotografije',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildPhotos(),
            ],
          ),
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

  Widget _buildPhotos() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: _load);
    }

    if (_photos.isEmpty) {
      return Text(
        'Nema priloženih fotografija.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _openFullscreen(photo),
          child: AuthenticatedImage(
            fetcher: () =>
                widget.service.fetchPhotoBytes(widget.report.id, photo.id),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _FullscreenPhotoScreen extends StatelessWidget {
  const _FullscreenPhotoScreen({required this.fileName, required this.fetcher});

  final String fileName;
  final Future<Uint8List> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(fileName),
      ),
      body: Center(
        child: InteractiveViewer(
          child: AuthenticatedImage(fetcher: fetcher, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
